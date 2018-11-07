require 'kron/helper/repo_fetcher'
require 'kron/accessor/index_accessor'
require 'kron/accessor/stage_accessor'
require 'digest'
module Kron
  module Repository
    include Kron::Accessor::IndexAccessor
    include Kron::Accessor::StageAccessor
    def clone(repo_uri, force = false, verbose = false)
      if Kron::Helper::RepoFetcher.from(repo_uri, force, verbose)
        # TODO: recovery the working directory from HEAD revision
      end
    end
    def add(file_path_list)
      index = load_index
      stage = load_stage
      file_path_list.each do |file_path|
        index.put(file_path)
        stage.put(file_path,"A")
      end
      sync_index(index)
      sync_stage(stage)
      # index.each_pair do |filename, hash|
      #
      # end
    end
    def serve(single_pass = true)
      # TODO: serve a packed repository for remote access
    end

    def add(paths, force = false)

    end

  end
end