module Bosh::Director
  module Jobs
    class DeleteOrphanDisks < BaseJob

      @queue = :normal

      def self.job_type
        :delete_orphan_disks
      end

      def self.enqueue(username, orphan_disk_cids, job_queue)
        persistent_disk_cids = orphan_disk_cids.select do |disk_cid|
          Bosh::Director::Models::PersistentDisk.where(disk_cid: disk_cid).any?
        end
        if persistent_disk_cids.any?
          raise DeletingPersistentDiskError, "Deleting persistent disk is not supported: #{persistent_disk_cids}"
        end

        job_queue.enqueue(username, Jobs::DeleteOrphanDisks, 'delete orphan disks', [orphan_disk_cids])
      end

      def initialize(orphan_disk_cids)
        @orphan_disk_cids = orphan_disk_cids
        @disk_manager = Bosh::Director::DiskManager.new(Config.cloud, Config.logger)
      end

      def perform
        # event_log.create_stage
        pool = ThreadPool.new(:max_threads => Config.max_threads).wrap do |pool|
          pool.process do
            success = @disk_manager.delete_orphan_disk(@orphan_disk_cids)
            # event_log.log
          end
        end

        pool.wait

        # report
        "orphaned disk(s) #{@orphan_disk_cids.join(', ')} deleted"
      end
    end
  end
end
