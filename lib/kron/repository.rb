require 'set'
require 'digest'
require 'pathname'
require 'colorize'
require 'kron/constant'
require 'kron/helper/repo_fetcher'
require 'kron/helper/repo_server'
require 'kron/accessor/index_accessor'
require 'kron/accessor/stage_accessor'
require 'kron/accessor/revisions_accessor'
require 'kron/accessor/manifest_accessor'
require 'kron/accessor/changeset_accessor'
require 'kron/domain/revisions'
require 'kron/domain/revision'
require 'kron/domain/manifest'
require 'zip'

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
      if Kron::Helper::RepoFetcher.from(repo_uri, BASE_DIR, force, verbose)
        # TODO: recovery the working directory from HEAD revision
      end
    end

    def add(file_path, force = false, recursive = true, verbose = true)
      index = load_index
      stage = load_stage
      file_paths = []
      if File.directory? file_path
        if recursive
          file_paths = Dir[File.join(file_path, '**', '*')].reject { |fn| File.directory?(fn) }
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
            # stage.remove_all path
            stage.to_modify << path # add -> modify file -> add ->  commit
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
          file_paths = Dir[File.join(file_path, '**', '*')].reject { |fn| File.directory?(fn) }
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
      revisions = load_rev
      if revisions.current[0].nil?
        raise StandardError, "HEAD detached at #{revisions.current[1]}"
      end

      hashes = Set.new index.each_pair.collect { |kv| kv[1][0] }
      Dir.glob(STAGE_DIR + '*/*').each do |file_hash|
        file_hash_ab = file_hash.split('/')[-2..-1].join('/')

        next unless hashes.include? file_hash_ab.split('/').join('')

        dst_path = OBJECTS_DIR + file_hash_ab
        FileUtils.mkdir_p(File.dirname(dst_path))
        FileUtils.mv file_hash, dst_path, force: true
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
      stage.to_add.each { |f| cs.put('@added_files', f) }
      stage.to_modify.each { |f| cs.put('@modified_files', f) }
      stage.to_delete.each { |f| cs.put('@deleted_files', f) }
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
      limit = revisions.heads.keys.map(&:length).max
      revisions.heads.keys.each do |branch_name|
        if revisions.current[0] == branch_name
          print "    #{branch_name.ljust(limit)}".colorize(color: :light_cyan, mode: :bold)
          puts ' <- HEAD'.colorize(color: :yellow, mode: :bold)
        else
          puts "    #{branch_name.ljust(limit)}"
        end
      end
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
    # end

    def rename_branch(old_name, new_name)
      revisions = load_rev
      raise StandardError, "branch '#{b_name}' not found" unless revisions.heads[old_name]

      revisions.heads.store(new_name, revisions.heads[old_name])
      revisions.heads.delete(old_name)
      sync_rev revisions
    end

    def checkout(target, is_branch = false, force = false, verbose = true)
      revisions = load_rev
      index = load_index
      stage = load_stage
      untracked = []
      unless force
        unless stage.to_add.empty? && stage.to_modify.empty? && stage.to_delete.empty?
          raise StandardError, 'something in stage need to commit'
        end
        wd = SortedSet.new
        Dir[File.join('**', '*')].reject { |fn| File.directory?(fn) }.each { |f| wd << f }
        tracked = Set.new
        index.each_pair do |file_path, args|
          tracked << file_path
          next unless wd.include? file_path
          if Digest::SHA1.file(file_path).hexdigest != args[0]
            raise StandardError, "modified files unstaged, use 'kron status' to check, '-f' to overwrite"
          end
        end

        untracked = wd - tracked
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
          # if no revision matched, downgrade to branch checking
          if revisions.heads.key?(target)
            is_branch = true
            new_branch = target
            revision_id = revisions.heads[target].id
          else
            raise StandardError, "revision '#{target}' not found"
          end
        else
          raise StandardError, "revision '#{target}' is ambiguous"
        end
      end
      mf = load_manifest(revision_id)

      unless force
        # check if its safe to proceed
        overwritten = []
        untracked.each do |path|
          overwritten << path unless mf[path].nil?
        end
        unless overwritten.empty?
          puts 'The following untracked working directory files would be overwritten by checkout:'
          puts
          overwritten.each { |path| puts "        #{path}".colorize(color: :red) }
          puts
          puts 'Please move or remove them before you switch branches.'
          return
        end
      end

      new_index = Kron::Domain::Index.new
      now_files = Set.new index.each_pair.collect { |kv| kv[0] }
      target_files = Set.new mf.each_pair.collect { |kv| kv[0] }
      to_rm_files = now_files - target_files
      to_rm_files.each do |file|
        FileUtils.rm_f File.join(WORKING_DIR, file)
      end
      # based on mf recover working directory and index.
      mf.each_pair do |file_name, paras|
        dir = paras[0][0..1]
        file_hash = paras[0][2..-1]
        FileUtils.mkdir_p File.dirname(file_name)
        FileUtils.cp File.join(OBJECTS_DIR, dir, file_hash), File.join(WORKING_DIR, file_name)
        new_index.put [file_name, paras].flatten
      end
      revisions.current = [new_branch, revisions.rev_map[revision_id]]
      sync_index(new_index)
      sync_rev(revisions)
      if verbose
        if is_branch
          puts "Switched to branch '#{target}'"
        else
          puts "Switched to revision '#{revision_id[0..DEFAULT_ABBREV - 1]}'"
          puts
          puts "You are now in 'detached HEAD' state, you need to declare a new"
          puts "branch (use 'kron branch add <branch>') before commit them, and you"
          puts "can discard you modification by performing another 'kron checkout'"
          puts
          puts "HEAD is now at #{revision_id}"
        end
      end
    end

    def status
      index = load_index
      stage = load_stage
      tracked = Set.new
      index.each_pair { |file_path, _args| tracked << file_path }
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
      Dir[File.join('**', '*')].reject { |fn| File.directory?(fn) }.each { |f| wd << f }
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
        print 'HEAD detached at '.colorize(color: :red)
        puts rev.current[1].id[0..DEFAULT_ABBREV - 1].to_s.colorize(color: :red, mode: :bold)
      else
        print 'On branch'
        puts " #{rev.current[0]}".colorize(color: :light_cyan, mode: :bold)
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
        stage.to_add.each { |f| puts "        new file:   #{f}".colorize(color: :green) }
        stage.to_modify.each { |f| puts "        modified:   #{f}".colorize(color: :yellow) }
        stage.to_delete.each { |f| puts "        deleted:   #{f}".colorize(color: :red) }
        puts
      end
      not_staged = n_stage_modified.empty? && n_stage_deleted.empty?
      unless not_staged
        puts 'Changes not staged for commit:'
        puts '  (use \'kron add <file>...\' to update what will be committed)'
        puts '  (use \'kron checkout -f\' to discard changes in working directory)'
        puts
        n_stage_modified.each { |f| puts "        modified:   #{f}".colorize(color: :red) }
        n_stage_deleted.each { |f| puts "        deleted:   #{f}".colorize(color: :red) }
        puts
      end
      unless untracked.empty?
        puts 'Untracked files:'
        puts '  (use \'kron add <file>...\' to include in what will be committed)'
        puts
        untracked.each { |f| puts "        #{f}".colorize(color: :red) }
        puts
      end
      if nothing_to_commit
        if not_staged
          if untracked.empty?
            puts 'nothing to commit, working directory clean'
          else
            puts 'nothing added to commit but untracked files present (use "kron add" to track)'
          end
        else
          puts 'no changes added to commit (use \'kron add\' to stage changes)'
        end
      end
    end

    def list_index
      index = load_index
      if index.each_pair.size > 0
        puts 'Tracked files:'
        size_limit = index.each_pair.map { |e| e[1][1].to_s.length }.max
        path_limit = index.each_pair.map { |e| e[0].to_s.length }.max
        index.each_pair.sort_by { |e| e[0] }.each do |file_path, attrs|
          print "    #{Time.at(attrs[2].to_i).strftime('%b %d %R')}".colorize(color: :green)
          print "  #{Time.at(attrs[3].to_i).strftime('%b %d %R')}".colorize(color: :yellow)
          print "  #{attrs[1].ljust(size_limit)}".colorize(color: :blue)
          print "  #{file_path.ljust(path_limit)}"
          puts attrs[0] == Digest::SHA1.file(file_path).hexdigest ? '' : ' (modified)'.to_s.colorize(color: :red)
        end
      else
        puts 'No tracked files.'
      end
    end

    # def extract_zip(file, destination)
    #   FileUtils.mkdir_p(destination)
    #
    #   Zip::File.open(file) do |zip_file|
    #     zip_file.each do |f|
    #       fpath = File.join(destination, f.name)
    #       zip_file.extract(f, fpath) unless File.exist?(fpath)
    #     end
    #   end
    # end
    def find_path(b1)
      path_b1 = []
      while b1
        path_b1 << b1
        b1 = b1.p_node
      end
    end

    def pull(name, tar_branch = 'zhang')
      # FileUtils.rm_rf File.join(WORKING_DIR, 'tmp') if File.exist? File.join(WORKING_DIR, 'tmp')


      FileUtils.mkdir File.join(WORKING_DIR, '.tmp')
      Zip::File.open(name, Zip::File::CREATE) do |zip_file|
        zip_file.each do |file|
          f_path = File.join(WORKING_DIR, '.tmp', file.name)
          zip_file.extract(file, f_path) unless File.exist?(f_path)
        end
      end
      tar_revisions = load_rev(File.join(BASE_DIR, 'tmp', 'rev'))
      revisions = load_rev
      cur_revision = revisions.heads[revisions.current[0]]
      tar_cur_revision = tar_revisions.heads[tar_branch]
      tmp_revision = tar_cur_revision
      ancestor_id = 0
      until tmp_revision.nil?
        if revisions.rev_map.key? tmp_revision.id
          ancestor_id = tmp_revision.id
          break
        else
          tmp_now_revision = tmp_revision
          tmp_revision = tmp_revision.p_node
          revisions.rev_map.store(tmp_revision.id, tmp_revision)
        end
      end

      raise StandardError, 'can not find common ancestor' if ancestor_id == 0
      # update revisions.heads {tar_branch:tar_cur_revision}
      revisions.heads.store(tar_branch, tar_cur_revision)
      tmp_now_revision.p_node = revisions.rev_map[ancestor_id]
      # sync_rev revisions


      # combine manifest
      Dir.foreach(File.join(WORKING_DIR, 'tmp', 'manifest')) do |file|
        unless File.exist?(File.join(MANIFEST_DIR, file))
          FileUtils.cp File.join(WORKING_DIR, 'tmp', 'manifest', file), File.join(MANIFEST_DIR, file)
        end
      end
      # combine changeset
      Dir.foreach(File.join(WORKING_DIR, 'tmp', 'changeset')) do |file|
        unless File.exist?(File.join(CHANGESET_DIR, file))
          FileUtils.cp File.join(WORKING_DIR, 'tmp', 'changeset', file), File.join(CHANGESET_DIR, file)
        end
      end
      #combine objects
      Dir.foreach(File.join(WORKING_DIR, 'tmp', 'objects')) do |subdir|
        if File.exist?(File.join(OBJECTS_DIR, subdir))
          if subdir != '.' && subdir != '..'
            Dir.foreach(File.join(WORKING_DIR, 'tmp', 'objects', subdir)) do |file|
              unless File.exist?(File.join(OBJECTS_DIR, subdir, file))
                FileUtils.cp File.join(WORKING_DIR, 'tmp', 'objects', subdir, file), File.join(OBJECTS_DIR, subdir, file)
              end
            end
          end
        else
          FileUtils.cp_r WORKING_DIR + 'tmp/objects/' + subdir + '/', OBJECTS_DIR + subdir
        end
        # unless File.exist?(File.join(CHANGESET_DIR, file))
        #   FileUtils.cp File.join(WORKING_DIR, 'tmp', 'changeset', file), File.join(CHANGESET_DIR, file)
        # end
      end
    end

    def serve(port, token, multiple_serve = false, quiet = false)
      Kron::Helper::RepoServer.new(port, token, multiple_serve, quiet).serve
    end

    def assert_repo_exist
      raise LoadError, 'not a kron repository (run \'kron init\' to create a new repo)' unless Dir.exist?(KRON_DIR)
    end

    def fetch_branch(brch, recursive = nil)
      rev = brch.id if brch
      log(rev)
      fetch_branch(brch.p_node, recursive) if recursive && brch
    end

    def log(revision = nil, branch = nil)
      return nil if !branch && !revision

      if branch
        brch = load_rev.heads[branch]
        fetch_branch(brch)
        return
      end
      cs = Kron::Domain::Changeset.new
      cs.rev_id = revision
      cs = load_changeset(cs)
      if cs
        puts "commit: #{revision}".colorize(color: :yellow)
        puts cs.to_s.string
      else
        puts 'unmatched revision id'
      end
    end

    def logs(branch = nil)
      buffer = {}
      if branch
        brch = load_rev.heads[branch]
        fetch_branch(brch, 1)
        return
      end
      Dir.glob(CHANGESET_DIR + '*').each do |file_path|
        revision = file_path.split('/')[-1]
        cs = Kron::Domain::Changeset.new
        cs.rev_id = revision
        cs = load_changeset(cs)
        buffer[cs.timestamp] = revision
      end
      buffer.keys.sort.reverse_each { |e| log(buffer[e]) }
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

    def head(branch = nil)
      rvs = load_rev
      rvs.heads.keys.each do |branch_name|
        if (branch == branch_name) || branch.nil?
          print "    #{branch_name}".colorize(color: :light_cyan)
          puts " <- HEAD #{rvs.heads[branch_name].id}".colorize(color: :yellow)
        end
      end
    end

  end
end
