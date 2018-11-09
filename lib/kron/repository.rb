require 'digest'
require 'pathname'
require 'kron/helper/repo_fetcher'
require 'kron/accessor/index_accessor'
require 'kron/accessor/stage_accessor'
require 'kron/accessor/revisions_accessor'
require 'kron/accessor/manifest_accessor'
require 'kron/accessor/changeset_accessor'
require 'kron/domain/revision'
require 'kron/domain/manifest'

module Kron
  module Repository
    include Kron::Accessor::IndexAccessor
    include Kron::Accessor::StageAccessor
    include Kron::Accessor::RevisionsAccessor
    include Kron::Accessor::ManifestAccessor
    include Kron::Accessor::ChangesetAccessor

    def init(force = false, verbose = false)
      raise StandardError, 'Repository already exists, use \'kron init -f\' to overwrite' if !force && Dir.exist?(KRON_DIR)

      FileUtils.rm_rf(KRON_DIR)
      FileUtils.mkdir(KRON_DIR)
      init_index
      init_changeset_dir
      init_manifest_dir
      puts 'Kron repository initialized.' if verbose
    end

    def clone(repo_uri, force = false, verbose = false)
      if Kron::Helper::RepoFetcher.from(repo_uri, force, verbose)
        # TODO: recovery the working directory from HEAD revision
      end
    end


    # TODO: recursive
    def add(file_path, force = false, recursive = true, verbose = true)
      # Pathspec matching
      index = load_index
      stage = load_stage
      file_paths = []
      if File.directory? file_path
        if recursive
          file_paths = Dir[File.join(file_path, '**', '*')].reject {|fn| File.directory?(fn)}
        else
          Dir.foreach(file_path) do |path|
            file_paths << path if File.file? path
          end
        end
      else
        file_paths = [file_path]
      end
      file_paths.each do |path|
        path = Pathname.new(path).realpath.relative_path_from(Pathname.new(WORKING_DIR)).to_s
        # if File.file? file_path
        unless File.exist? path
          puts "Pathspec '#{path}' did not match any files" if verbose
          next
        end
        if !force && stage.include?(path)
          puts "File '#{path}' has already added to stage, use 'kron add -f' to overwrite."
          next
        end

        new_hash = Digest::SHA1.file(path).hexdigest
        if index.include? path
          stage.to_modify << path
          # p 'to_modify' + stage.to_add.to_s
          old_hash = index[path][0]
          if old_hash == new_hash
            puts "File '#{path}' unchanged, skip add." if verbose
            next
          end
          if stage.to_modify? path
            # multi-declared modification, delete previous stage first
            FileUtils.rm_f(File.join(STAGE_DIR, old_hash[0..1], old_hash[2..-1]))
          end
        else
          if stage.to_delete? path
            stage.to_delete.delete path
            stage.to_modify << path
          else

            stage.to_add << path
          end
        end
        index.put path
        FileUtils.mkdir_p File.join(STAGE_DIR, new_hash[0..1])
        FileUtils.copy(path, File.join(STAGE_DIR, new_hash[0..1], new_hash[2..-1]))
        puts "File '#{path}' added." if verbose

      end
      sync_index(index)
      sync_stage(stage)
    end

    def remove(file_path, check = true, recursive = true, rm = true, verbose = true)
      file_paths = []
      if File.directory? file_path
        if recursive
          file_paths = Dir[File.join(file_path, '**', '*')].reject {|fn| File.directory?(fn)}
        else
          raise StandardError, "not removing '#{file_path}', recursively without -r"
        end
      else
        file_paths << file_path
      end
      index = load_index
      stage = load_stage
      file_paths.each do |file_path|
        next unless index.include? file_path
        hash = index[file_path][0]
        if check && Digest::SHA1.file(file_path).hexdigest != hash
          puts "File '#{file_path}' was modified, use 'kron rm -f' to delete is anyway."
          next
        end

        if stage.to_add? file_path
          stage.to_add.delete file_path
          FileUtils.rm_f File.join(STAGE_DIR, hash[0..1], hash[2..-1])
        elsif stage.to_modify file_path
          stage.to_modify.delete file_path
          stage.to_delete << file_path
          FileUtils.rm_f File.join(STAGE_DIR, hash[0..1], hash[2..-1])
        end
        index.remove file_path
        if rm
          FileUtils.rm_f file_path
          puts "File '#{file_path}' removed." if verbose
        else
          puts "File '#{file_path}' removed from the tracking list." if verbose
        end
      end
      sync_index(index)
      sync_stage(stage)
      FileUtils.rm_rf WORKING_DIR + file_path
    end

    def commit(message, author = nil, branch = nil, verbose = false)
      index = load_index
      stage = load_stage
      p stage.nil?

      # TODO: check stage

      # load Revisions
      revisions = load_rev # TODO: not implemented
      Dir.glob(STAGE_DIR + '*/*').each do |file_path|
        dst_path = OBJECTS_DIR + file_path.split('/')[-2..-1].join('/')
        FileUtils.mkdir_p(File.dirname(dst_path))
        FileUtils.mv file_path, dst_path, force: true
      end

      # add Manifest TODO: why didn't directly copy it in disk?
      mf = Kron::Domain::Manifest.new
      mf.rev_id = 'new_manifest.tmp'
      index.each_pair do |k, v|
        mf.put [k, v].flatten
      end

      # add Changeset
      cs = Kron::Domain::Changeset.new
      stage.to_add.each {|f| cs.put('@added_files', f)}
      stage.to_modify.each {|f| cs.put('@modified_files', f)}
      stage.to_delete.each {|f| cs.put('@deleted_files', f)}
      cs.commit_message = message
      cs.author = author
      cs.timestamp = Time.now.to_i

      # add a revision
      revision = Kron::Domain::Revision.new
      revision.p_node = revisions.current[1]
      # revision.id = Digest::SHA1.hexdigest cs.to_s + mf.to_s # TODO: use file digest instead
      revision.id = Digest::SHA1.hexdigest Time.now.to_s # TODO: use file digest instead
      revisions.add_revision(revision)
      mf.rev_id = revision.id
      cs.rev_id = revision.id
      sync_changeset(cs)
      sync_manifest(mf)
      remove_stage
      # FileUtils.rm_f STAGE_PATH
      # Dir.glob(STAGE_DIR + '*').each do |file|
      #   Dir.delete file
      # end
    end

    def status
      puts "index:     #{load_index.items}"
      puts "to_add:    #{load_stage.to_add}"
      puts "to_modify: #{load_stage.to_modify}"
      puts "to_remove: #{load_stage.to_delete}"
      # stat = {"u"=>[], "a"=>[], "m"=>[], "r"=>[]}
      #
      # index = load_index
      # Find.find(KRON_DIR) do |path|
      #   unless index.include?(path)
      #     stat['u'].push(path)
      #   end
      #   index_sha1 = index[path][0]
      #   file_sha1 = Digest::SHA1.file(file_path).hexdigest
      #   if index_sha1 == file_sha1
      #     stat['a'].push(path)
      #   else
      #     stat['m'].push(path)
      #   end
      # end
    end

    def serve(single_pass = true)
      # TODO: serve a packed repository for remote access
    end
  end
end