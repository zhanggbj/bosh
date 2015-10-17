require 'spec_helper'

module Bosh::Director
  describe Jobs::DeleteOrphanDisks do

    describe '.enqueue' do
      let(:job_queue) { instance_double(JobQueue) }

      it 'enqueues a DeleteOrphanDisks job' do
        fake_orphan_disk_cids = ['fake-cid-1', 'fake-cid-2']

        expect(job_queue).to receive(:enqueue).with('fake-username', Jobs::DeleteOrphanDisks, 'delete orphan disks', [fake_orphan_disk_cids])
        Jobs::DeleteOrphanDisks.enqueue('fake-username', fake_orphan_disk_cids, job_queue)
      end

      it 'errors if disk is not orphaned' do
        persistent_disk_cid = Models::PersistentDisk.make.disk_cid
        expect do
          Jobs::DeleteOrphanDisks.enqueue(nil, [persistent_disk_cid], JobQueue.new)
        end.to raise_error(DeletingPersistentDiskError)
      end
    end
  end
end
