require 'kron/domain/revisions'
require 'kron/domain/revision'
require 'kron/accessor/revisions_accessor'
require 'digest'
require 'kron/repository'
include Kron::Accessor::RevisionsAccessor
include Kron::Repository

# add(['test1.txt'])
# commit('','Normal')
# remove(["test.txt"])
# FileUtils.copy "test.txt","test1.txt"
# File.new(".kron/objects/as/test.txt","w") do |f|
#   f.puts "test"
# end
# Dir.mkdir(".kron/objects/as/"
# FileUtils.mv '.kron/objects/4e', '.kron'

#