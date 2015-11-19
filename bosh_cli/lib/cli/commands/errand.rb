require 'cli/client/errands_client'

module Bosh::Cli::Command
  class Errand < Base
    usage 'errands'
    desc 'List available errands'
    def errands
      deployment_required
      errands = list_errands

      if errands.size > 0
        errands_table = table do |t|
          t.headings = ['Name']
          errands.each { |errand| t << [errand['name']] }
        end
        nl
        say(errands_table)
      else
        err("Deployment has no available errands")
      end
    end

    usage 'run errand'
    desc 'Run specified errand'
    option '--download-logs', 'download logs'
    option '--logs-dir destination_directory', String, 'logs download directory'
    option '--keep-alive', 'prevent deletion/creation of vm after running errand'
    def run_errand(errand_name=nil)
      auth_required
      deployment_required

      unless errand_name
        errand = prompt_for_errand_name
        errand_name = errand['name']
      end
      perform_run_errand(errand_name)
    end

    private
    def perform_run_errand(errand_name)
      deployment_name = prepare_deployment_manifest(show_state: true).name

      errands_client = Bosh::Cli::Client::ErrandsClient.new(director)
      status, task_id, errand_result = errands_client.run_errand(deployment_name, errand_name, options[:keep_alive] || FALSE)

      unless errand_result
        task_report(status, task_id, nil, "Errand `#{errand_name}' did not complete")
        return
      end

      nl

      download_dir = nil

      if errand_result.logs_blobstore_id && errand_result.std_streams_as_files
        # Here we know the director supports std_streams_as_files, and it has sent back a
        # logs_blobstore_id attribute in the result.

        if options[:download_logs]
          # Keep the downloaded logs somewhere
          download_dir = options[:logs_dir] || Dir.pwd
        else
          # Make download_logs a tmp directory, as it will be deleted after displaying all the logs
          download_dir =  Dir.tmpdir
        end

      else
        # Here we know it is either a director version that does not support std_streams_as_files, or
        # the director did not specify a blobstore id. In either case, this means we should fall back to display
        # errand_result.stdout and errand_result.stderr. The agent may have truncated these to respect NATS message limits
        download_dir = options[:logs_dir] || Dir.pwd

        say('[stdout]')
        say(errand_result.stdout.empty?? 'None' : errand_result.stdout)
        nl

        say('[stderr]')
        say(errand_result.stderr.empty?? 'None' : errand_result.stderr)
        nl
      end

      if errand_result.logs_blobstore_id && (options[:download_logs] || errand_result.std_streams_as_files)
        # Here we know that the director specified a blobstore id. We should download the logs if download_logs was passed
        # or std_streams_as_files is supported by the director. The path to where logs will be downloaded was already
        # specified through the download_dir variable
        logs_downloader = Bosh::Cli::LogsDownloader.new(director, self)
        logs_path = logs_downloader.build_destination_path(errand_name, 0, download_dir)

        begin
          logs_downloader.download(errand_result.logs_blobstore_id, logs_path, !options[:download_logs])
        rescue Bosh::Cli::CliError => e
          @download_logs_error = e
        end

        if errand_result.std_streams_as_files
          # Here we know that the director supports std_streams_as_files, so we unzip the logs in a tmp directory,
          # read all the log files and then display them in the output.
          Dir.mktmpdir { |unpack_dir|
            unpack_logs(unpack_dir, logs_path)
            unpack_pattern = File.join(unpack_dir, "**", "*")
            log_files = Dir.glob(unpack_pattern).select{ |e| File.file? e }

            log_files.each { |filename|
              log_file = File.open(filename,"r")

              begin
                say("[#{filename[unpack_dir.length, filename.length - unpack_dir.length]}]")
                say(log_file.read)
              ensure
                log_file.close unless log_file.nil?
              end

              nl
            }
          }
        end
      end

      title_prefix = "Errand `#{errand_name}'"
      exit_code_suffix = "(exit code #{errand_result.exit_code})"

      if errand_result.exit_code == 0
        say("#{title_prefix} completed successfully #{exit_code_suffix}".make_green)
      elsif errand_result.exit_code > 128
        err("#{title_prefix} was canceled #{exit_code_suffix}")
      else
        err("#{title_prefix} completed with error #{exit_code_suffix}")
      end

      raise @download_logs_error if @download_logs_error
    end

    def unpack_logs(unpack_dir, tarball_path)
      !!system("tar", "-C", unpack_dir, "-xzf", tarball_path, out: "/dev/null", err: "/dev/null")
    end

  end
end
