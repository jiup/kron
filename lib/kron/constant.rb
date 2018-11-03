require 'digest'

class Constant
  INDEX_FILE = 'index'.freeze
  STAGE_FILE = 'stage'.freeze
  REV_FILE = 'rev'.freeze
  MANIFEST_DIR = 'manifest/'.freeze
  CHANGESET_DIR = 'changeset/'.freeze
  OBJECTS_BASE = 'objects/'.freeze

  DIGEST_ALGO = Digest::SHA1
end