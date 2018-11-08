require 'kron/helper/repo_fetcher'
require 'kron/accessor/index_accessor'
require 'kron/accessor/stage_accessor'
require 'digest'
require 'kron/domain/manifest'
require 'kron/accessor/manifest_accessor'
require 'kron/domain/revision'
require 'kron/accessor/revisions_accessor'
require 'kron/accessor/changeset_accessor'
module Kron
  module Repository
    include Kron::Accessor::IndexAccessor
    include Kron::Accessor::StageAccessor
    include Kron::Accessor::ChangesetAccessor
    include Kron::Accessor::ManifestAccessor


    def clone(repo_uri, force = false, verbose = false)
      if Kron::Helper::RepoFetcher.from(repo_uri, force, verbose)
        # TODO: recovery the working directory from HEAD revision
      end
    end

    def store(file, path)
      dir = path[0..1]
      file_path = path[1..-1]
      Dir.mkdir STAGE_DIR + dir unless Dir.exist? STAGE_DIR + dir
      FileUtils.copy file, File.join(STAGE_DIR + dir, file_path)
    end

    def add(file_path_list)
      index = load_index
      stage = load_stage
      file_path_list.each do |file_path|
        if index.in_index? file_path
          stage.put(file_path, "M")
          index.put(file_path)
        else
          if stage.in_stage? file_path && stage.added_files[file_path] == 'D'
            stage.put(file_path, "M")
            index.put(file_path)
          else
            stage.put(file_path, "A")
            index.put(file_path)
          end
        end
        store(file_path, Digest::SHA1.file(file_path).hexdigest)
        # FileUtils.copy file_path, STAGE_DIR + Digest::SHA1.file(file_path).hexdigest
      end
      sync_index(index)
      sync_stage(stage)
    end

    def remove(file_path_list)

      index = load_index
      stage = load_stage
      file_path_list.each do |file_path|
        if index.in_index? file_path
          path = STAGE_DIR + index[file_path][0]
          index.remove(file_path)
        end
        if stage.in_stage? file_path && stage.added_files[file_path] == 'A'
          stage.remove(file_path)
          FileUtils.rm_f path
          # internal logic : file_path is in stage no matter it is "A" or "M" it must in index. so path must be initialized before use

        elsif stage.in_stage? file_path && stage.added_files[file_path] == 'M'
          stage.put(file_path, "D")
          FileUtils.rm_f path
        end
      end
      sync_index(index)
      sync_stage(stage)
    end

    def commit(massage, mode = "Normal")
      if mode == "Normal"
        index = load_index
        stage = load_stage
        # load revisions
        revisions = Kron::Accessor::StageAccessor.load_rev
        # copy
        # stage.each_stage do file
        #   # FileUtils.copy file, OBJECTS_DIR + Digest::SHA1.file(file).hexdigest
        #   store(file,OBJECTS_DIR + Digest::SHA1.file(file).hexdigest)
        # end
        Dir.foreach(STAGE_DIR) do |dir|
          if !(dir == '.') and !(dir == '..')
            if File.exist? OBJECTS_DIR + dir
              Dir.foreach(STAGE_DIR + dir) do |file|
                FileUtils.mv File.join(STAGE_DIR + dir, file), OBJECTS_DIR + dir, :force => true
              end
            else
              FileUtils.mv (STAGE_DIR + dir), OBJECTS_DIR, :force => true
            end
          end
        end
        #add Manifest
        mf = Kron::Domain::Manifest.new
        index.each_pair do |k, v|
          mf.put [k, v].flatten
        end

        #add Changeset
        cs = Kron::Domain::Changeset.new
        stage.each_pair do |file, file_mode|
          if file_mode == "A"
            cs.put("@added_files", file)
          elsif file_mode == "D"
            cs.put("@deleted_files", file)
          elsif file_mode == "M"
            cs.put("@modified_files", file)
          end
        end
        # add a revision
        revision = Kron::Domain::Revision.new
        revision.p_node = revisions.current[1]
        revision.id = Digest::SHA1.hexdigest cs.to_s + mf.to_s
        revisions.add_revision(revision)
        Kron::Accessor::ChangesetAccessor.sync_changeset(cs, revision.id)
        Kron::Accessor::ManifestAccessor.sync_manifest(mf, revision.id)
        FileUtils.rm_f STAGE_PATH
      end

    end

    def serve(single_pass = true)
      # TODO: serve a packed repository for remote access
    end
  end
end