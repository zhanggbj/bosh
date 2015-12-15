require 'rubygems/package'

module Bosh
  module Dev
    class GemComponent
      ROOT = File.expand_path('../../../../../', __FILE__)

      attr_reader :name, :version

      def initialize(name, version)
        @name = name
        @version = version
      end

      def dot_gem
        "#{name}-#{version}.gem"
      end

      def build_gem(destination)
        Dir.chdir(name) do
          spec = Gem::Specification.load "#{name}.gemspec"
          spec.version = version
          output = Gem::Package.build spec
          FileUtils.mv(output, destination)
        end
      end

      def dependencies
        gemfile_lock_path = File.join(ROOT, 'Gemfile.lock')
        lockfile = Bundler::LockfileParser.new(File.read(gemfile_lock_path))

        Bundler::Resolver.resolve(
          Bundler.definition.send(:expand_dependencies, Bundler.definition.dependencies.select { |d| d.name == name }),
          Bundler.definition.index,
          {},
          lockfile.specs
        )
      end
    end
  end
end
