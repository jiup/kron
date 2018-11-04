require 'gli'

module Kron
  # Kron Command Line Interface
  module CLI
    extend GLI::App

    program_desc 'A light-weight distributed version control software'
    switch %i[v verbose], desc: 'Show verbose messages', negatable: false
    switch %i[h help], desc: 'Show this message', negatable: false

    desc 'Create an empty Kron repository'
    command :init do |c|
      c.desc 'Reinitialize if repository already exists'
      c.switch %i[f force], negatable: false

      c.action do |_global_options, options, _args|
        if !options[:f]
          puts 'todo: default repo_init' else puts 'todo: force repo_init'
        end
      end
    end

    desc 'Show current version'
    command :version do |c|
      c.action do |global_options, _options, _args|
        global_options[:verbose] ? puts("kron version #{VERSION}") : puts(VERSION)
      end
    end

    exit run(ARGV)
  end
end