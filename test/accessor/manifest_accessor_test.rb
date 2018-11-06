require 'minitest/autorun'
require 'kron/accessor/manifest_accessor'
require 'kron/domain/manifest'

class ManifestAccessorTest < Minitest::Test
  include Kron::Accessor::ManifestAccessor

  def test_init_and_remove_directory
    # init_dir
    # assert_raises(StandardError) { init_dir }
    # init_dir(true)
    # remove_dir
    # remove_dir

    # mf = Kron::Domain::Manifest.new("123")
    # Dir.glob('../**/*') { |f| mf.put(f) if File.file? f }
    # sync_manifest(mf)
    # mf2 = load_manifest "123"
    # mf2.each_pair do |k, v|
    #   puts "#{k} ===> #{v}"
    # end
    # mf.each_pair do |k, v|
    #   puts "#{k} ===> #{v}"
    # end
  end
end