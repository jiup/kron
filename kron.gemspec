
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kron/version'

Gem::Specification.new do |spec|
  spec.name          = 'kron'
  spec.version       = Kron::VERSION
  spec.authors       = ['Jiupeng Zhang']
  spec.email         = ['jiupeng.zhang@rochester.edu']

  spec.summary       = 'a light-weight distributed version control software'
  spec.description   = 'course project for csc453'
  spec.homepage      = 'https://github.com/jiup/kron'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/jiup/kron/tree/master/src'
    spec.metadata['changelog_uri'] = "https://github.com/jiup/kron/blob/master/Changelog.md"
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'gli', '~> 2.18.0'
  spec.add_development_dependency 'colorize', '~> 0.8.1'
  spec.add_development_dependency 'rubyzip', '~> 1.2.2'
end
