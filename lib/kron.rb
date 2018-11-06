require 'kron/version'
require 'kron/cli'

module Kron
  include Kron::CLI

  def self.included(_klass)
    warn 'you should include Kron::CLI instead'
  end
end