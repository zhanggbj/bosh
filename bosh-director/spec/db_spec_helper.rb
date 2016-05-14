$: << File.expand_path('..', __FILE__)

require 'rspec'
require 'rspec/its'
require 'sequel'
require_relative '../../bosh-director/lib/bosh/director/config'

module DBSpecHelper
  class << self
    attr_reader :db

    def init
      puts "PWD in DBSpecHelper.init: #{Dir.pwd}"
      @temp_dir = Bosh::Director::Config.generate_temp_dir
      @director_migrations_dir = File.expand_path('../../db/migrations/director', __FILE__)
      puts "director_migrations_dir: #{@director_migrations_dir}"
     Sequel.extension :migration
    end

    def connect_database(path)
      puts ENV['DB']

      case @db.class.to_s
        when /postgresql/
          db_path     = ENV['DB_CONNECTION']     || "postgres://postgres:postgres@localhost:5432/director"
        when /mysql/
          raise "mysql not supported!!!"
        else
          db_path     = ENV['DB_CONNECTION']     || "sqlite://#{File.join(path, "director.db")}"
      end

      db_opts = {:max_connections => 32, :pool_timeout => 10}

      @db = Sequel.connect(db_path, db_opts)
    end

    def reset_database

      case @db.class.to_s
        when /Postgres/
          @db.run('drop schema public cascade;')
          @db.run('create schema public;')
        when /Mysql/
          raise "mysql not supported!!!"
        when /Sqlite/
          FileUtils.rm_rf(@db_dir) if @db_dir
          @db_dir = Dir.mktmpdir(nil, @temp_dir)

          FileUtils.rm_rf(@migration_dir) if @migration_dir
          @migration_dir = Dir.mktmpdir('migration-dir', @temp_dir)
      end

      if @db
        @db.disconnect
        @db = nil
      end

      connect_database(@temp_dir)
    end



    def migrate_all_before(migration_file)
      reset_database
      puts "PWD in DBSpecHelper.migrate_all_before: #{Dir.pwd}"
      @director_migrations_dir ||= File.expand_path('../../db/migrations/director', __FILE__)
      migration_file_full_path = File.join(@director_migrations_dir, migration_file)
      files_to_migrate = Dir.glob("#{@director_migrations_dir}/*").select do |filename|
        filename < migration_file_full_path
      end
      # raise "files_to_migrate is nil!!!" if @files_to_migrate.nil?
      # raise "director_migrations_dir is nil ( in migrate_all_before )!!!" if @director_migrations_dir.nil?
      puts "files to migrate:"
      puts files_to_migrate.nil? ? "nil" : files_to_migrate.pretty_inspect
      puts "@migration_dir:"
      puts @migration_dir.nil? ? "nil" : @migration_dir.pretty_inspect
      FileUtils.cp_r(files_to_migrate, @migration_dir)
      Sequel::TimestampMigrator.new(@db, @migration_dir, {}).run
    end

    def migrate(migration_file)
      migration_file_full_path = File.join(@director_migrations_dir, migration_file)
      FileUtils.cp(migration_file_full_path, @migration_dir)
      Sequel::TimestampMigrator.new(@db, @migration_dir, {}).run
    end
  end
end
raise "before the require"
DBSpecHelper.init
