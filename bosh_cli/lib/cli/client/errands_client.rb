require 'multi_json'

module Bosh::Cli::Client
  class ErrandsClient
    class ErrandResult
      attr_reader :exit_code, :stdout, :stderr, :logs_blobstore_id, :std_streams_as_files

      def initialize(exit_code, stdout, stderr, logs_blobstore_id, std_streams_as_files)
        @exit_code = exit_code
        @stdout = stdout
        @stderr = stderr
        @logs_blobstore_id = logs_blobstore_id
        @std_streams_as_files = std_streams_as_files
      end

      def ==(other)
        unless other.is_a?(self.class)
          raise ArgumentError, "Must be #{self.class} to compare"
        end

        local = [exit_code, stdout, stderr, logs_blobstore_id, std_streams_as_files]
        other = [other.exit_code, other.stdout, other.stderr, other.logs_blobstore_id, other.std_streams_as_files]
        local == other
      end
    end

    def initialize(director)
      @director = director
    end

    def run_errand(deployment_name, errand_name, keep_alive)
      url = "/deployments/#{deployment_name}/errands/#{errand_name}/runs"
      payload = MultiJson.encode({'keep-alive' => (keep_alive || FALSE)})
      options = { content_type: 'application/json', payload: payload }

      status, task_id = @director.request_and_track(:post, url, options)

      unless [:done, :cancelled].include?(status)
        return [status, task_id, nil]
      end

      errand_result_output = @director.get_task_result_log(task_id)
      errand_result = nil

      if errand_result_output
        task_result = JSON.parse(errand_result_output)
        errand_result = ErrandResult.new(
          *task_result.values_at('exit_code', 'stdout', 'stderr'),
          task_result.fetch('logs', {})['blobstore_id'],
          task_result.fetch('logs', {})['std_streams_as_files']
        )
      end

      [status, task_id, errand_result]
    end
  end
end
