module Bosh::Stemcell
  class StemcellBuilder
    def initialize(dependencies = {})
      @gem_components = dependencies.fetch(:gem_components)
      @environment = dependencies.fetch(:environment)
      @runner = dependencies.fetch(:runner)
      @definition = dependencies.fetch(:definition)
    end

    def build
      collection = Bosh::Stemcell::StageCollection.new(definition)

      gem_components.build_release_gems
      environment.prepare_build
      stemcell_stages = collection.extract_operating_system_stages +
        collection.agent_stages +
        collection.build_stemcell_image_stages
      runner.configure_and_apply(stemcell_stages)

      definition.disk_formats.each do |disk_format|
        runner.configure_and_apply(collection.package_stemcell_stages(disk_format))
      end
    end

    private

    attr_reader :gem_components, :environment, :collection, :runner, :definition
  end
end
