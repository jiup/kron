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
          stage.put(file_path, 'M')
          if stage.in_stage? file_path
            FileUtils.rm_f File.join(STAGE_DIR + index[file_path][0][0..1], index[file_path][0][1..-1])
          end
          index.put(file_path)
        else
          if stage.in_stage? file_path && stage.added_files[file_path] == 'D'
            stage.put(file_path, 'M')
            index.put(file_path)
          else
            stage.put(file_path, 'A')
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
          stage.put(file_path, 'D')
          FileUtils.rm_f path
        end
      end
      sync_index(index)
      sync_stage(stage)
    end

    def commit(massage, mode = 'Normal')
      if mode == 'Normal'
        index = load_index
        stage = load_stage
        # load revisions
        revisions = Kron::Accessor::StageAccessor.load_rev
        Dir.glob(STAGE_DIR + '*/*').each do |file_path|
          dst_path = OBJECTS_DIR + file_path.split('/')[-2..-1].join('/')
          FileUtils.mkdir_p(File.dirname(dst_path))
          FileUtils.mv file_path, dst_path, force: true
        end
        #add Manifest
        mf = Kron::Domain::Manifest.new
        index.each_pair do |k, v|
          mf.put [k, v].flatten
        end

        #add Changeset
        cs = Kron::Domain::Changeset.new
        stage.each_pair do |file, file_mode|
          if file_mode == 'A'
            cs.put('@added_files', file)
          elsif file_mode == 'D'
            cs.put('@deleted_files', file)
          elsif file_mode == 'M'
            cs.put('@modified_files', file)
          end
        end
        # add a revision
        revision = Kron::Domain::Revision.new
        revision.p_node = revisions.current[1]
        revision.id = Digest::SHA1.hexdigest cs.to_s + mf.to_s
        revisions.add_revision(revision)
        mf.rev_id = revision.id
        Kron::Accessor::ChangesetAccessor.sync_changeset(cs, revision.id)
        Kron::Accessor::ManifestAccessor.sync_manifest(mf)
        FileUtils.rm_f STAGE_PATH
        Dir.glob(STAGE_DIR + '*').each do |file|
          Dir.delete file
        end
      end

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