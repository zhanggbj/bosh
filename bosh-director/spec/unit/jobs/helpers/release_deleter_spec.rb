require 'spec_helper'

module Bosh::Director
  module Jobs::Helpers
    describe ReleaseDeleter do
      subject(:release_deleter) { ReleaseDeleter.new(package_deleter, template_deleter, Config.event_log, logger) }

      let(:package_deleter) { PackageDeleter.new(compiled_package_deleter, blobstore, logger) }
      let(:template_deleter) { TemplateDeleter.new(blobstore, logger) }
      let(:compiled_package_deleter) { CompiledPackageDeleter.new(blobstore, logger) }
      let(:blobstore) { instance_double(Bosh::Blobstore::BaseClient) }

      describe '#delete' do
        let(:release) { Models::Release.make(name: 'release-1') }
        let!(:release_version_1) { Models::ReleaseVersion.make(version: 1, release: release) }
        let!(:release_version_2) { Models::ReleaseVersion.make(version: 2, release: release) }
        let!(:package_1) { Models::Package.make(release: release, blobstore_id: 'package-blob-id-1') }
        let!(:package_2) { Models::Package.make(release: release, blobstore_id: 'package-blob-id-2') }
        let!(:template_1) { Models::Template.make(release: release, blobstore_id: 'template-blob-id-1') }
        let!(:template_2) { Models::Template.make(release: release, blobstore_id: 'template-blob-id-2') }
        let(:force) { false }

        before do
          allow(blobstore).to receive(:delete)
        end

        let(:act) { release_deleter.delete(release, force) }

        describe 'success' do
          it 'deletes the packages, templates, release versions, and release' do
            act

            expect(Models::ReleaseVersion.all).to be_empty
            expect(Models::Package.all).to be_empty
            expect(Models::Template.all).to be_empty
            expect(Models::Release.all).to be_empty
          end
        end

        describe 'when package deletion fails' do
          before do
            allow(blobstore).to receive(:delete).with('package-blob-id-1').and_raise('nope')
          end

          it 'does not delete database entries' do
            expect{ act }.to raise_error('nope')
            expect(Models::ReleaseVersion.all).to_not be_empty
            expect(Models::Package.all).to_not be_empty
            expect(Models::Template.all).to_not be_empty
            expect(Models::Release.all).to_not be_empty
          end

          describe 'when forced' do
            let(:force) { true }

            it 'deletes the packages, templates, release versions, and release' do
              act
              expect(Models::Package.all).to be_empty
              expect(Models::Template.all).to be_empty
              expect(Models::ReleaseVersion.all).to be_empty
              expect(Models::Release.all).to be_empty
            end
          end
        end

        describe 'when template deletion fails' do
          before do
            allow(blobstore).to receive(:delete).with('template-blob-id-1').and_raise('nope')
          end

          it 'does not delete templates, release versions and release but deletes packages' do
            expect{ act }.to raise_error('nope')
            expect(Models::Package.all).to be_empty
            expect(Models::Template.all).to_not be_empty
            expect(Models::ReleaseVersion.all).to_not be_empty
            expect(Models::Release.all).to_not be_empty
          end

          describe 'when forced' do
            let(:force) { true }
            it 'deletes the packages, templates, release versions, and release' do
              act
              expect(Models::Package.all).to be_empty
              expect(Models::Template.all).to be_empty
              expect(Models::ReleaseVersion.all).to be_empty
              expect(Models::Release.all).to be_empty
            end
          end
        end
      end
    end
  end
end
