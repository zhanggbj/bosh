require 'bosh/dev'
require 'bosh/dev/build'
require 'bosh/dev/gem_components'
require 'bosh/stemcell/build_environment'
require 'bosh/stemcell/definition'
require 'bosh/stemcell/stage_collection'
require 'bosh/stemcell/stage_runner'
require 'bosh/stemcell/stemcell_packager'
require 'bosh/stemcell/checkpointed_runner'
require 'bosh/stemcell/stage'
require 'bosh/stemcell/git'
require 'git'

module Bosh::Dev
  module Stemcell
    class Builder
      def initialize(infrastructure_name, hypervisor_name, operating_system_name, operating_system_version, agent_name, os_image_path)
        @infrastructure_name = infrastructure_name
        @hypervisor_name = hypervisor_name
        @operating_system_name = operating_system_name
        @operating_system_version = operating_system_version
        @agent_name = agent_name
        @os_image_path = os_image_path
      end

      def build(resume_build)
        build = Bosh::Dev::Build.candidate
        gem_components = Bosh::Dev::GemComponents.new(build.number)
        gem_components.build_release_gems
        definition = Bosh::Stemcell::Definition.for(@infrastructure_name, @hypervisor_name, @operating_system_name, @operating_system_version, @agent_name, false)
        environment = Bosh::Stemcell::BuildEnvironment.new(
          ENV.to_hash,
          definition,
          build.number,
          build.release_tarball_path,
          @os_image_path,
        )

        # system(environment.os_image_rspec_command)

        runner = Bosh::Stemcell::StageRunner.new(
          build_path: environment.build_path,
          command_env: environment.command_env,
          settings_file: environment.settings_path,
          work_path: environment.work_path,
        )

        stemcell_building_stages = Bosh::Stemcell::StageCollection.new(definition)

        packager = Bosh::Stemcell::StemcellPackager.new(
          definition,
          environment.version,
          environment.work_path,
          environment.stemcell_tarball_path,
          runner,
          stemcell_building_stages,
        )

        stemcell_stages = stemcell_building_stages.extract_operating_system_stages +
          stemcell_building_stages.agent_stages +
          stemcell_building_stages.build_stemcell_image_stages

        start = Bosh::Stemcell::Stage.new(:run_configure_scripts){
          runner.configure(stemcell_stages)
        }.chain.append(
          stemcell_stages.map do |stage|
            Bosh::Stemcell::Stage.new("apply_stage_for #{stage}") { runner.apply([stage]) }
          end
        ).next(Bosh::Stemcell::Stage.new(:configuring_and_applying_packaging_scripts){
          runner.configure_and_apply(stemcell_building_stages.package_stemcell_stages(disk_format))
          mkdir_p('tmp')
        }).branch(
          *definition.disk_formats.map do |disk_format|
            Bosh::Stemcell::Stage.new(:write_manifest){
              packager.write_manifest(disk_format)
            }.chain.next(Bosh::Stemcell::Stage.new(:create_stemcell_tarball){
              stemcell_tarball = packager.create_tarball(disk_format)
              raise "wheres my tarball?" if stemcell_tarball.nil?
              cp(stemcell_tarball, 'tmp')
            }).done
          end
        ).done

        Git.configure do |config|
          config.binary_path = 'sudo git' #to git add the chroot
        end

        git = Bosh::Stemcell::Git.new(environment.base_directory)
        checkpointed_runner = Bosh::Stemcell::CheckpointedRunner.new(git)

        checkpointed_runner.validate!(start)

        if resume_build
          puts "*"*80
          puts "We're resuming"
          puts "*"*80
          environment.prepare_build
          checkpointed_runner.resume(start)
        else
          environment.sanitize
          environment.prepare_build
          git.delete
          git.init
          checkpointed_runner.run(start)
        end

        system(environment.stemcell_rspec_command)

        git.delete
      end
    end
  end
end
