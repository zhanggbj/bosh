module Bosh::Cli
  class JobState
    OPERATION_DESCRIPTIONS = {
        start: 'start %s',
        stop: 'stop %s',
        detach: 'stop %s and power off its VM(s)',
        restart: 'restart %s',
        recreate: 'recreate %s'
    }

    NEW_STATES = {
        start: 'started',
        stop: 'stopped',
        detach: 'detached',
        restart: 'restart',  # TODO: restarted ???
        recreate: 'recreate' # TODO: recreated ???
    }

    COMPLETION_DESCRIPTIONS = {
        start: '%s started',
        stop: '%s stopped, VM(s) still running',
        detach: '%s detached, VM(s) powered off',
        restart: '%s restarted',
        recreate: '%s recreated'
    }

    def initialize(command, manifest)
      @command = command
      @manifest = manifest
    end

    def change(job, state, index, force)
      description = job_description(job, index)
      operation = OPERATION_DESCRIPTIONS.fetch(state) % description
      new_state = NEW_STATES.fetch(state)
      completion = COMPLETION_DESCRIPTIONS.fetch(state) % description.make_green

      status, task_id = change_vm_state(job, index, new_state, operation, force)
      [status, task_id, completion]
    end

    private
    attr_reader :command

    def job_description(job, index)
      return 'all jobs' if job == :all
      index ? "#{job}/#{index}" : "#{job}/ALL"
    end


    def change_vm_state(job, index, new_state, operation_desc, force)
      command.say("You are about to #{operation_desc.make_green}")

      check_if_manifest_changed(@manifest.hash, force)

      unless command.confirmed?("#{operation_desc.capitalize}?")
        command.cancel_deployment
      end

      command.nl
      command.say("Performing '#{operation_desc}'...")
      command.director.change_job_state(@manifest.name, @manifest.yaml, new_state, job, index)
    end

    def check_if_manifest_changed(manifest_hash, force)
      other_changes_present = command.inspect_deployment_changes(manifest_hash, show_empty_changeset: false)

      if other_changes_present && !force
        command.err("Cannot perform job management when other deployment changes are present. Please use '--force' to override.")
      end
    end
  end
end
