require 'digest'
require 'pathname'
require 'colorize'
require 'kron/helper/repo_fetcher'
require 'kron/accessor/index_accessor'
require 'kron/accessor/stage_accessor'
require 'kron/accessor/revisions_accessor'
require 'kron/accessor/manifest_accessor'
require 'kron/accessor/changeset_accessor'
require 'kron/domain/revisions'
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
        path = Pathname.new(path).realpath.relative_path_from(Pathname.new(WORKING_DIR)).to_s if File.exist?(path)
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
          else
            stage.to_modify << path
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
        puts "File '#{path}' added to stage." if verbose
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
        path = Pathname.new(path).realpath.relative_path_from(Pathname.new(WORKING_DIR)).to_s if File.exist?(path)
        unless index.include? path
          if verbose
            puts File.exist?(path) ? "File '#{path}' is not tracked." : "File '#{path}' not found."
          end
          next
        end

        hash = index[path][0]
        if check && File.exist?(path) && Digest::SHA1.file(path).hexdigest != hash
          puts "File '#{path}' was modified, use 'kron rm -f' to delete it without check."
          next
        end

        if stage.to_add? path
          stage.to_add.delete path
          FileUtils.rm_f File.join(STAGE_DIR, hash[0..1], hash[2..-1])
        elsif stage.to_modify? path
          stage.to_modify.delete path
          stage.to_delete << path
          FileUtils.rm_f File.join(STAGE_DIR, hash[0..1], hash[2..-1])
        else
          stage.to_delete << path
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
      if stage.to_add.empty? && stage.to_modify.empty? && stage.to_delete.empty?
        raise StandardError, 'nothing to commit, working directory clean.'
      end

      # load Revisions
      revisions = load_rev # TODO: not implemented
      if revisions.current[0].nil?
        raise StandardError, "HEAD detached at #{revisions.current[1]}"
      end

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
      sync_changeset(cs)
      sync_manifest(mf)
      manifest_hash = Digest::SHA1.file(MANIFEST_DIR + 'new_manifest.tmp').hexdigest
      changeset_hash = Digest::SHA1.file(CHANGESET_DIR + 'new_changeset.tmp').hexdigest
      rev_id = (manifest_hash.to_i(16) ^ changeset_hash.to_i(16)).to_s(16)
      revision.id = rev_id
      revisions.add_revision(revision)
      File.rename(MANIFEST_DIR + 'new_manifest.tmp', MANIFEST_DIR + rev_id)
      File.rename(CHANGESET_DIR + 'new_changeset.tmp', CHANGESET_DIR + rev_id)
      sync_rev(revisions)
      remove_stage
    end

    # @param [Object] b_name
    # def branch(b_name, is_delete = false)
    #   revisions = load_rev
    #
    #   raise StandardError, "branch '#{b_name}' already exist" if revisions.heads[b_name]
    #
    #   revisions.current[0] = b_name if revisions.current[0].nil?
    #   revisions.heads.store(b_name, revisions.current[1])
    # end

    def add_branch(b_name)
      if (b_name =~ /^[a-zA-Z0-9]{1,32}$/).nil?
        raise StandardError, "branch name  '#{b_name}' is invalid"
      end

      revisions = load_rev
      revisions.current[0] = b_name if revisions.current[0].nil?
      # revisions.branch_hook
      if revisions.heads[b_name]
        raise StandardError, "branch '#{b_name}' already exist"
      end

      revisions.heads.store(b_name, revisions.current[1])
      # p revisions.heads
      sync_rev revisions
    end

    def list_branch
      revisions = load_rev
      revisions.heads.keys
    end

    # def delete_revision(rev)
    #   if rev.p_node.branch == rev.branch
    #     delete_branch(rev.p_node)
    #   else
    #     rev_id = rev.id
    #     File.rm_rf File.join(MANIFEST_DIR, rev_id)
    #     File.rm_rf File.join(CHANGESET_DIR, rev_id)
    #     rev.
    #   end
    # end

    # def delete_branch(b_name)
    #   revisions = load_rev
    #   raise StandardError, "branch '#{b_name}' not found" unless revisions.heads[b_name]
    #   b_to_delete = revisions.heads[b_name]
    #
    #   revisions.heads.delete(b_name)
    #
    # end

    def rename_branch(old_name, new_name)
      revisions = load_rev
      raise StandardError, "branch '#{b_name}' not found" unless revisions.heads[old_name]

      revisions.heads.store(new_name, revisions.heads[old_name])
      revisions.heads.delete(old_name)
      sync_rev revisions
    end

    def checkout(target, is_branch = false, force = false)
      revisions = load_rev
      index = load_index
      stage = load_stage
      unless force
        unless stage.to_add.empty? && stage.to_modify.empty? && stage.to_delete.empty?
          raise StandardError, 'something in stage need to commit'
        end

        tracked = Set.new
        index.each_pair {|file_path, _args| tracked << file_path}
        wd = SortedSet.new
        Dir[File.join('**', '*')].reject {|fn| File.directory?(fn)}.each {|f| wd << f}
        unless (wd - tracked).empty?
          raise StandardError, "untracked files #{(wd - tracked)}"
        end
      end

      if is_branch
        if revisions.heads.key?(target)
          new_branch = target
          revision_id = revisions.heads[target].id

        else
          raise StandardError, "branch '#{target}' not found"
        end
      else
        matched = []
        revisions.rev_map.each_key do |id|
          matched << id unless (id =~ /#{target}/).nil?
        end
        if matched.size == 1
          new_branch = nil
          revision_id = matched[0]
        elsif matched.empty?
          raise StandardError, "revision '#{target}' not found"
        else
          raise StandardError, "revision '#{target}' is not only one"
        end
      end
      mf = load_manifest(revision_id)
      new_index = Kron::Domain::Index.new

      # based on mf recover working directory and index.
      mf.each_pair do |file_name, paras|
        dir = paras[0][0..1]
        file_hash = paras[0][2..-1]
        FileUtils.mkdir_p File.dirname(file_name)
        FileUtils.cp File.join(OBJECTS_DIR, dir, file_hash), File.join(WORKING_DIR, file_name)
        new_index.put [file_name, paras].flatten
      end

      revisions.current = [new_branch, revision_id]

      sync_index(new_index)
      sync_rev(revisions)
    end

    def status
      index = load_index
      stage = load_stage
      tracked = Set.new
      index.each_pair {|file_path, _args| tracked << file_path}
      n_stage_modified = []
      n_stage_deleted = []
      tracked.each do |p|
        if File.exist? p
          n_stage_modified << p unless index[p][0] == Digest::SHA1.file(p).hexdigest
        else
          n_stage_deleted << p
        end
      end
      wd = SortedSet.new
      Dir[File.join('**', '*')].reject {|fn| File.directory?(fn)}.each {|f| wd << f}
      untracked = wd - tracked

      # exclude by parsing .kronignore file
      if File.exist? IGNORE_PATH
        File.open(IGNORE_PATH).each do |regex|
          untracked.delete_if do |path|
            !regex.start_with?('#') && path.match?(regex)
          end
        end
      end

      rev = load_rev
      if rev.current[0].nil?
        puts "HEAD detached at #{rev.current[1]}".colorize(color: :red)
      else
        print 'On branch'
        puts " #{rev.current[0]}".colorize(color: :light_cyan)
      end
      if rev.current[1] == rev.heads[rev.current[0]]
        puts 'Your branch is up to date.'
        puts
      end
      nothing_to_commit = stage.to_add.empty? && stage.to_modify.empty? && stage.to_delete.empty?
      unless nothing_to_commit
        puts 'Changes to be committed:'
        puts '  (use \'kron rm -c stage\' to unstage)'
        puts
        stage.to_add.each {|f| puts "        new file: #{f}".colorize(color: :green)}
        stage.to_modify.each {|f| puts "        modified: #{f}".colorize(color: :yellow)}
        stage.to_delete.each {|f| puts "        deleted: #{f}".colorize(color: :red)}
        puts
      end
      not_staged = n_stage_modified.empty? && n_stage_deleted.empty?
      unless not_staged
        puts 'Changes not staged for commit:'
        puts '  (use \'kron add <file>...\' to update what will be committed)'
        puts '  (use \'kron checkout -f\' to discard changes in working directory)'
        puts
        n_stage_modified.each {|f| puts "        modified: #{f}".colorize(color: :red)}
        n_stage_deleted.each {|f| puts "        deleted: #{f}".colorize(color: :red)}
        puts
      end
      unless untracked.empty?
        puts 'Untracked files:'
        puts '  (use \'kron add <file>...\' to include in what will be committed)'
        puts
        untracked.each {|f| puts "        #{f}".colorize(color: :red)}
        puts
      end
      if nothing_to_commit
        if not_staged
          puts 'nothing to commit, working directory clean'
        else
          puts 'no changes added to commit (use \'kron add\' to stage changes)'
        end
      end
    end

    def serve(single_pass = true)
      # TODO: serve a packed repository for remote access
    end

    def assert_repo_exist
      raise LoadError, 'not a kron repository (run \'kron init\' to create a new repo)' unless Dir.exist?(KRON_DIR)
    end
  end
end
