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

    def add(file_path, force = false, recursive = true, verbose = true)
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
        unless File.exist? path
          puts "File '#{path}' not found." if verbose
          next
        end
        if !force && stage.include?(path)
          puts "File '#{path}' has already added to stage, use 'kron add -f' to overwrite."
          next
        end

        new_hash = Digest::SHA1.file(path).hexdigest
        if index.include? path
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
          raise StandardError, "Not removing '#{file_path}', recursively without -r"
        end
      else
        file_paths << file_path
      end
      index = load_index
      stage = load_stage
      file_paths.each do |path|
        unless index.include? path
          if verbose
            puts File.exist?(path) ? "File '#{path}' is not tracked." : "File '#{path}' not found."
          end
          next
        end

        hash = index[path][0]
        if check && Digest::SHA1.file(path).hexdigest != hash
          puts "File '#{path}' was modified, use 'kron rm -f' to delete is anyway."
          next
        end

        if stage.to_add? path
          stage.to_add.delete path
          FileUtils.rm_f File.join(STAGE_DIR, hash[0..1], hash[2..-1])
        elsif stage.to_modify path
          stage.to_modify.delete path
          stage.to_delete << path
          FileUtils.rm_f File.join(STAGE_DIR, hash[0..1], hash[2..-1])
        end
        index.remove path
        if rm
          FileUtils.rm_f path
          puts "File '#{path}' removed." if verbose
        else
          puts "File '#{path}' removed from the tracking list." if verbose
        end
      end
      sync_index(index)
      sync_stage(stage)
    end

    def commit(message, author = nil, branch = nil, verbose = false)

      index = load_index
      stage = load_stage

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
      cs.rev_id = 'new_changeset.tmp'
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

      sync_changeset(cs)
      sync_manifest(mf)
      manifest_hash = Digest::SHA1.file(MANIFEST_DIR + 'new_manifest.tmp').hexdigest
      changeset_hash = Digest::SHA1.file(CHANGESET_DIR + 'new_changeset.tmp').hexdigest
      rev_id = (manifest_hash.to_i(16) ^ changeset_hash.to_i(16)).to_s(16)

      revision.id = rev_id # TODO: use file digest instead
      revisions.add_revision(revision)
      File.rename(MANIFEST_DIR + 'new_manifest.tmp',MANIFEST_DIR+rev_id)
      File.rename(CHANGESET_DIR + 'new_changeset.tmp',CHANGESET_DIR+rev_id)
      sync_rev(revisions)
      remove_stage
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

    def log(revision = nil, branch = nil)
      return nil if !branch && !revision

      cs = Kron::Domain::Changeset.new
      cs.rev_id = revision
      cs = load_changeset(cs)
      if cs
        puts cs.to_s.string
      else
        puts "unmatched revision id"
      end
    end

    def logs(branch = nil)
      buffer = StringIO.new
      Dir.glob(CHANGESET_DIR + '*').each do |file_path|
        buffer.puts log(file_path.split('/')[-1])
      end
      puts buffer.string
    end

    def cat(rev_id = nil, branch = nil, paths)
      return nil unless rev_id

      buffer = StringIO.new
      mf = load_manifest(rev_id)
      raise StandardError, 'unmatched revision id' unless mf

      paths.each do |path|
        buffer.puts "#{path}:\n"
        hash = mf[path]
        src = File.join(OBJECTS_DIR + [hash[0][0..1], hash[0][2..-1]].join('/')) if hash
        if hash && File.exist?(src)
          File.read(src).each_line do |row|
            buffer.puts row
          end
        else
          buffer.puts 'File Not Found.'
        end
      end
      puts buffer.string
    end

  end
end