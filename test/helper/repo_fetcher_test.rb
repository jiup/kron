require 'minitest/autorun'
require 'kron/helper/repo_fetcher'

class RepoFetcherTest < Minitest::Test
  def test_local_fetcher
    assert_raises StandardError do
      Kron::Helper::LocalFetcher.from('./no_repo_here/', true)
    end
  end
end