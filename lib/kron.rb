require 'kron/version'
require 'kron/cli'
require 'kron/constant'
require 'kron/repository'
require 'kron/accessor/changeset_accessor'
require 'kron/accessor/index_accessor'
require 'kron/accessor/manifest_accessor'
require 'kron/accessor/rev_accessor'
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
  include Kron::CLI

  def self.included(_klass)
    warn 'you should include Kron::CLI instead'
  end
end