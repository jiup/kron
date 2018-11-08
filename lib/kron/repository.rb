require 'kron/helper/repo_fetcher'
require 'kron/accessor/index_accessor'
require 'kron/accessor/stage_accessor'
require 'digest'
require 'kron/domain/manifest'
require 'kron/accessor/manifest_accessor'
require 'kron/domain/revision'
require 'kron/accessor/revisions_accessor'
module Kron
  module Repository
    include Kron::Accessor::IndexAccessor
    include Kron::Accessor::StageAccessor


    def clone(repo_uri, force = false, verbose = false)
      if Kron::Helper::RepoFetcher.from(repo_uri, force, verbose)
        # TODO: recovery the working directory from HEAD revision
      end
    end

    def store(file, path)
      FileUtils.copy file, path
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
        store(file_path, STAGE_DIR + Digest::SHA1.file(file_path).hexdigest)
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
          path = STAGE_DIR+index[file_path][0]
          index.remove(file_path)
        end
        if stage.in_stage? file_path && stage.added_files[file_path] == 'A'
          stage.remove(file_path)
          FileUtils.rm_f path
          # internal logic : file_path is in stage no matter it is "A" or "M" it must in index. so path must be initialized before use

        elsif stage.in_stage? file_path && stage.added_files[file_path] == 'M'
          stage.put(file_path,"D")
          FileUtils.rm_f path
        end
      end
      sync_index(index)
      sync_stage(stage)
    end

    def commit(massage)
      index = load_index
      stage = load_stage
      revisions = Kron::Accessor::StageAccessor.load_rev
      p_id = revisions.current[1]
      stage.each_stage do
        file
        FileUtils.copy file, OBJECTS_DIR + Digest::SHA1.file(file).hexdigest
      end
      revision = Kron::Domain::Revision.new
      revision.id = OBJECTS_DIR + Digest::SHA1.file(INDEX_PATH).hexdigest
      mf = Kron::Domain::Manifest.new('')
      index.each_pair do |k, v|
        mf.put [k, v].flatten
      end

    end

    def serve(single_pass = true)
      # TODO: serve a packed repository for remote access
    end
  end
end