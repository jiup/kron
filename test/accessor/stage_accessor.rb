require_relative  '../../lib/kron/accessor/stage_accessor'
require  '../../lib/kron/domain/stage'

class StageAccessorTest
  include Kron::Accessor::StageAccessor
end

stgacr = StageAccessorTest.new
stg = Kron::Domain::Stage.new
stg.added_files = ["a.txt","b.txt"]
#stgacr.init_file
#stgacr.remove_file
p stgacr.load_stage