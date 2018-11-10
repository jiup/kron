require 'gli'
require 'securerandom'
require 'kron/constant'
require 'kron/repository'
require 'kron/accessor/changeset_accessor'
require 'kron/accessor/index_accessor'
require 'kron/accessor/manifest_accessor'
require 'kron/accessor/revisions_accessor'
require 'kron/accessor/stage_accessor'
require 'kron/domain/changeset'
require 'kron/domain/index'
require 'kron/domain/manifest'
require 'kron/domain/revision'
require 'kron/domain/revisions'
require 'kron/domain/stage'
require 'kron/domain/working_directory'
require 'kron/helper/repo_fetcher'

module Kron
  # Kron Command Line Interface
  module CLI
    extend GLI::App
    extend GLI::StandardException
    extend Repository

    program_desc 'A light-weight distributed version control software'
    version Kron::VERSION
    sort_help :manually
    switch %i[v verbose], desc: 'Show verbose messages', negatable: false
    switch %i[h help], desc: 'Show this message', negatable: false

    desc 'Show the current version'
    command :version do |c|
      c.action do |global_options, _options, _args|
        global_options[:verbose] ? puts("kron version #{VERSION}") : puts(VERSION)
      end
    end

    desc 'Create an empty kron repository'
    command [:init, :create] do |c|
      c.desc 'Reinitialize if a repository already exists'
      c.switch %i[f force], negatable: false
      c.action do |global_options, options, args|
        help_now!('no arguments required') unless args.empty?
        init(options[:f], global_options[:v])
      end
    end

    desc 'Clone a repository to current directory'
    arg '<repo_uri>', :required
    command [:clone] do |c|
      c.desc 'Overwrite if a repository already exists, changes are not recoverable'
      c.switch %i[f force], negatable: false
      c.action do |global_options, options, repo_uri|
        help_now!('repo_uri is required') if repo_uri.empty?
        clone(repo_uri.join(' '), options[:f], global_options[:verbose])
      end
    end

    desc 'Add file contents to the index'
    arg '<file_name>', :required
    command :add do |c|
      c.desc 'Overwrite if file(s) already added to stage'
      c.switch %i[f force], negatable: false
      c.desc 'Allow recursive add when a leading directory name is given'
      c.switch %i[r], negatable: false
      c.desc 'Suppress the output'
      c.switch %i[q quiet], negatable: false
      c.action do |_global_options, options, file_paths|
        help_now!('file_name is required') if file_paths.empty?
        assert_repo_exist
        file_paths.each do |file_path|
          add(file_path, options[:f], options[:r], !options[:q])
        end
      end
    end

    desc 'Remove files from the working directory and index'
    arg '<file_name>', :required
    command [:rm, :remove] do |c|
      c.desc 'Override the up-to-date check'
      c.switch %i[f force], negatable: false
      c.desc 'Allow recursive removal when a leading directory name is given'
      c.switch %i[r], negatable: false
      c.desc 'Unstage files only from the index, working tree files will be left alone'
      c.switch %i[c cached], negatable: false
      c.desc 'Suppress the output'
      c.switch %i[q quiet], negatable: false
      c.action do |_global_options, options, file_paths|
        help_now!('file_name is required') if file_paths.empty?
        assert_repo_exist
        file_paths.each do |file_path|
          remove(file_path, !options[:f], options[:r], !options[:c], !options[:q])
        end

      end
    end

    desc 'Show the working directory status'
    command :status do |c|
      c.action do |_global_options, _options, args|
        help_now!('no arguments required') unless args.empty?
        assert_repo_exist
        status
      end
    end

    desc 'Record changes to the repository'
    command :commit do |c|
      c.desc 'Suppress the output'
      c.switch %i[q quiet], negatable: false
      c.desc 'Set commit message for a revision'
      c.flag %i[m message], arg_name: '<msg>', multiple: true, required: true
      c.desc 'Set the branch to commit'
      c.flag %i[b branch], arg_name: '<branch>'
      c.desc 'Specify an explicit author for the commit'
      c.flag %i[u author], arg_name: '<author>'
      c.action do |global_options, options, args|
        help_now!('no arguments required') unless args.empty?
        assert_repo_exist
        if options[:m].empty? || options[:m].first.strip.empty?
          exit_now!('please specify commit message')
        end
        commit(options[:m].join('\n'), options[:u], options[:b], global_options[:v])
      end
    end

    desc 'Print commit log'
    command :log do |c|
      c.desc 'Show log of a specific revision'
      c.flag %i[c revision], arg_name: '<rev_id>'
      c.desc 'Show latest log of a specific branch'
      c.flag %i[b branch], arg_name: '<branch>'
      c.action do |_global_options, _options, _args|
        exit_now! 'Command not implemented'
      end
    end

    desc 'Show commit logs'
    command :logs do |c|
      c.desc 'Show logs on a branch'
      c.flag %i[b branch], arg_name: '<branch>'
      c.action do |_global_options, _options, _args|
        exit_now! 'Command not implemented'
      end
    end

    desc 'Print text of a file of a specific revision'
    command [:cat, :lookup] do |c|
      c.desc 'Show file content of a specific revision'
      c.flag %i[c revision], arg_name: '<rev_id>'
      c.desc 'Show latest file revision of a branch'
      c.flag %i[b branch], arg_name: '<branch>'
      c.action do |_global_options, _options, _args|
        help_now!('no arguments required') unless args.empty?

        exit_now! 'Command not implemented'
      end
    end

    desc 'Show head revisions'
    command [:head, :heads] do |c|
      c.desc 'Show head of a branch'
      c.flag %i[b branch], arg_name: '<branch>'
      c.action do |_global_options, _options, _args|
        exit_now! 'Command not implemented'
      end
    end

    desc 'List, create, or delete branches'
    arg '<branch>'
    command :branch do |c|
      c.desc 'List all branches'
      c.command :list do |cc|
        cc.action do |_global_options, _options, args|
          help_now!('no arguments required') unless args.empty?
          p list_branch()
          p 'list branches'
        end
      end
      c.desc 'Create a branch'
      c.arg '<branch>'
      c.command :add do |cc|
        cc.action do |_global_options, _options, args|
          assert_repo_exist
          help_now!('branch name required') unless args.length == 1
          p "add branch #{args[0]}"
        end
      end
      c.desc 'Delete a branch'
      c.arg '<branch>'
      c.command [:rm, :delete] do |cc|
        cc.action do |_global_options, _options, args|
          assert_repo_exist
          help_now!('branch name required') unless args.length == 1
          p "delete branch #{args[0]}"
          exit_now! 'Command not implemented'
        end
      end
      c.desc 'Rename a branch'
      c.arg '<old_branch> <new_branch>'
      c.command [:mv, :rename] do |cc|
        cc.action do |_global_options, _options, args|
          assert_repo_exist
          help_now!('arguments <old_branch> <new_branch> required') unless args.length == 2
          p "rename branch #{args[0]} to #{args[1]}"
          exit_now! 'Command not implemented'
        end
      end
      c.default_command :add
    end

    desc 'Switch branches and restore working directory files'
    arg '<commit>'
    command [:checkout, :goto] do |c|
      c.desc 'Proceed even if the index or the working directory differs from HEAD'
      c.switch %i[f force], negatable: false
      c.desc 'Prepare for working on a specific <branch>'
      c.flag %i[b branch], arg_name: '<branch>'
      c.action do |_global_options, options, args|
        assert_repo_exist
        if options[:b].nil?
          help_now!('single argument <commit> required') if args.length != 1
          checkout(args[0], false, options[:f])
        else
          help_now!('no arguments required') unless args.empty?
          checkout(options[:b], true, options[:f])
        end
      end
    end

    desc 'Join two or more development histories together'
    arg '<branch_name>'
    command [:merge] do |c|
      # TODO: add more flags
      c.desc 'Show a diff stat only, no file will be changed'
      c.switch %i[n stat], negatable: false
      c.desc 'Suppress the output'
      c.switch %i[q quiet], negatable: false
      c.action do |_global_options, _options, _args|
        exit_now! 'Command not implemented'
      end
    end

    desc 'Fetch from and integrate with another repository'
    arg '<repo_uri>', :required
    command [:pull, :fetch] do |c|
      c.action do |_global_options, _options, repo_uri|
        help_now!('repo_uri is required') if repo_uri.empty?
        exit_now! 'Command not implemented'
      end
    end

    desc 'Update remote refs along with associated objects'
    arg '<repo_uri>', :required
    command [:push, :sync] do |c|
      c.action do |_global_options, _options, repo_uri|
        help_now!('repo_uri is required') if repo_uri.empty?
        exit_now! 'Command not implemented'
      end
    end

    desc 'Start kron server for remote transmission'
    command [:serve] do |c|
      c.desc 'Suppress the output'
      c.switch %i[q quiet], negatable: false
      c.desc 'Close server after a single serve'
      c.switch %i[s single-serve], negatable: false
      c.desc 'Specific token for remote service, if this field not given, an random token will be used'
      c.flag %i[t token], mask: true, arg_name: '<token>', default_value: SecureRandom.alphanumeric(DEFAULT_TOKEN)
      c.action do |_global_options, options, args|
        help_now!('no arguments required') unless args.empty?
        puts "service_token: #{options[:token]}"
        exit_now! 'Command not implemented'
      end
    end

    exit run(ARGV)
  end
end