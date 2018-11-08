require 'kron/helper/repo_fetcher'
require 'kron/accessor/index_accessor'
require 'kron/accessor/stage_accessor'
require 'digest'
require 'find'
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

    def status
      stat = {"u"=>[], "a"=>[], "m"=>[], "r"=>[]}

      index = load_index
      Find.find(KRON_DIR) do |path|
        unless index.in_index?(path)
          stat['u'].push(path)
        end
        index_sha1 = index[path][0]
        file_sha1 = Digest::SHA1.file(file_path).hexdigest
        if index_sha1 == file_sha1
          stat['a'].push(path)
        else
          stat['m'].push(path)
        end
      end
    end

    def init
      Dir.mkdir(KRON_DIR)
      init_dir
      Kron::Accessor::ChangesetAccessor.init_dir
      Kron::Accessor::IndexAccessor.init_dir
      Kron::Accessor::ManifestAccessor.init_dir
      Kron::Accessor::StageAccessor.init_dir

    end

  end
end