module Bosh
  module Director
    class DependencyKeyGenerator
      def generate_from_models(package, release_version)
        package_hashes = transitive_dependencies(package, release_version).map do |package|
          {
            'name' => package.name,
            'version' => package.version,
            'dependencies' => []
          }
        end

        package_hashes.map do |package_hash|
          arrayify(package_hash, package_hashes.dup)
        end.to_s.gsub(' ', '')

      end

      def generate_from_manifest(package_name, compiled_packages)
        @all_packages = compiled_packages
        package = compiled_packages.find { |package| package['name'] == package_name }

        package['dependencies'].map do |dependency_name|
          arrayify(find_package_hash(dependency_name), all_packages.dup)
        end.to_s.gsub(' ','')

      end

      private

      attr_reader :all_packages

      def transitive_dependencies(package, release_version)
        dependency_set = Set.new
        dependencies(package, release_version).each do |dependency|
          dependency_set << dependency
          dependency_set.merge(transitive_dependencies(dependency, release_version))
        end
        dependency_set
      end

      def dependencies(package, release_version)
        package.dependency_set.map { |package_name| package_by_name_and_release_version(package_name, release_version) }.to_set
      end

      def package_by_name_and_release_version(package_name, release_version)
        release_version.packages.find do |p|
          p.name == package_name
        end
      end

      def arrayify(package, remaining_packages)
        remaining_packages.delete(package)

        [
          package['name'],
          package['version']
        ].tap do |output|
          if package['dependencies'] && package['dependencies'].length > 0
            output << package['dependencies'].map { |sub_dep| arrayify(find_package_hash(sub_dep), remaining_packages) }
          end
          output
        end
      end

      def find_package_hash(name)
        all_packages.find { |package| package['name'] == name }
      end
    end
  end
end
