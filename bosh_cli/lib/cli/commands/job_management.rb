# Copyright (c) 2009-2012 VMware, Inc.
require 'cli/job_state'

module Bosh::Cli
  module Command
    class JobManagement < Base
      FORCE = 'Proceed even when there are other manifest changes'

      # bosh start
      usage 'start'
      desc 'Start job/instance'
      option '--force', FORCE
      def start_job(job, index = nil)
        change_job_state(job, :start, index)
      end

      # bosh stop
      usage 'stop'
      desc 'Stop job/instance'
      option '--soft', 'Stop process only'
      option '--hard', 'Power off VM'
      option '--force', FORCE
      def stop_job(job = :all, index = nil)
        if hard?
          change_job_state(job, :detach, index)
        else
          change_job_state(job, :stop, index)
        end
      end

      # bosh restart
      usage 'restart'
      desc 'Restart job/instance (soft stop + start)'
      option '--force', FORCE
      def restart_job(job, index = nil)
        change_job_state(job, :restart, index)
      end

      # bosh recreate
      usage 'recreate'
      desc 'Recreate job/instance (hard stop + start)'
      option '--force', FORCE
      def recreate_job(job, index = nil)
        change_job_state(job, :recreate, index)
      end

      private

      def change_job_state(job, state, index = nil)
        auth_required
        manifest = parse_manifest(state)

        job_state = JobState.new(self, manifest)
        status, task_id, completion_desc = job_state.change(job, state, index, force?)
        task_report(status, task_id, completion_desc)
      end

      def hard?
        options[:hard]
      end

      def soft?
        options[:soft]
      end

      def force?
        options[:force]
      end

      def parse_manifest(operation)
        manifest = prepare_deployment_manifest(show_state: true)

        # TODO: doesn't belong here
        if hard? && soft?
          err('Cannot handle both --hard and --soft options, please choose one')
        end

        # TODO: doesn't belong here
        if !hard_and_soft_options_allowed?(operation) && (hard? || soft?)
          err("--hard and --soft options only make sense for 'stop' operation")
        end

        manifest
      end

      def hard_and_soft_options_allowed?(operation)
        operation == :stop || operation == :detach
      end
    end
  end
end
