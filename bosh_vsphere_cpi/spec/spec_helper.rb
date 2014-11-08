require File.expand_path('../../../spec/shared_spec_helper', __FILE__)
require File.expand_path('../../../spec/support/buffered_logger', __FILE__)

require 'sequel'
require 'sequel/adapters/sqlite'

Sequel.extension :migration
db = Sequel.sqlite(':memory:')
migration = File.expand_path('../../db/migrations', __FILE__)
Sequel::TimestampMigrator.new(db, migration, :table => 'vsphere_cpi_schema').run

require 'cloud'
require 'cloud/vsphere'

class VSphereSpecConfig
  attr_accessor :db, :logger, :uuid
end

config = VSphereSpecConfig.new
config.db = db
config.uuid = '123'

Bosh::Clouds::Config.configure(config)

RSpec.configure do |example|
  example.before do
    config.logger = logger
  end
end

def by(message)
  if block_given?
    yield
  else
    pending message
  end
end

alias and_by by
