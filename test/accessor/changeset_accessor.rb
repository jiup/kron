require_relative  '../../lib/kron/accessor/changeset_accessor'
require '../../lib/kron/domain/changeset'

class ChangesetAccessorTest
  include Kron::Accessor::ChangesetAccessor
end
#
# test = ChangesetAccessorTest.new
# test.init_dir(true)
# changset = Kron::Domain::Changeset.new(2)
# changset.commit_message = "commited 2"
# test.sync_changeset(changset)
# chst = test.load_changeset("2")
# p chst
