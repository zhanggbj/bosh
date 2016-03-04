require 'spec_helper'
require 'yaml'

module Bosh::Director
  describe DependencyKeyGenerator do

    let(:key_generator) { DependencyKeyGenerator.new }

    context 'given a compiled packages from the manifest' do
      context 'when package has no dependencies' do
        let(:compiled_packages) { [] }

        xit 'should generate a dependency key' do
          key = key_generator.generate_from_manifest('bad-package', compiled_packages)
          expect(key).to eq '[]'
        end
      end

      context 'when package has no dependencies' do
        let(:compiled_packages) do
          [
            {
              'name' => 'fake-pkg0',
              'version' => 'fake-pkg0-version',
              'fingerprint' => 'fake-pkg0-fingerprint',
              'stemcell' => 'ubuntu-trusty/3000',
              'dependencies' => []
            },
            {
              'name' => 'fake-pkg2',
              'version' => 'fake-pkg2-version',
              'fingerprint' => 'fake-pkg2-fingerprint',
              'stemcell' => 'ubuntu-trusty/3000',
              'dependencies' => []
            },
          ]
        end

        it 'should generate a dependency key' do
          key = key_generator.generate_from_manifest('fake-pkg0', compiled_packages)
          expect(key).to eq('[]')
        end
      end
    end

    context 'when package has more than 1 level deep transitive dependencies' do
      let(:compiled_packages) do
        [
          {
            'name' => 'fake-pkg0',
            'version' => 'fake-pkg0-version',
            'fingerprint' => 'fake-pkg0-fingerprint',
            'stemcell' => 'ubuntu-trusty/3000',
            'dependencies' => ['fake-pkg2']
          },
          {
            'name' => 'fake-pkg1',
            'version' => 'fake-pkg1-version',
            'fingerprint' => 'fake-pkg1-fingerprint',
            'stemcell' => 'ubuntu-trusty/3000',
            'dependencies' => []
          },
          {
            'name' => 'fake-pkg2',
            'version' => 'fake-pkg2-version',
            'fingerprint' => 'fake-pkg2-fingerprint',
            'stemcell' => 'ubuntu-trusty/3000',
            'dependencies' => ['fake-pkg3']
          },
          {
            'name' => 'fake-pkg3',
            'version' => 'fake-pkg3-version',
            'fingerprint' => 'fake-pkg3-fingerprint',
            'stemcell' => 'ubuntu-trusty/3000',
            'dependencies' => []
          },
        ]
      end

      it 'should generate a dependency key' do
        key = key_generator.generate_from_manifest('fake-pkg0', compiled_packages)
        expect(key).to eq('[["fake-pkg2","fake-pkg2-version",[["fake-pkg3","fake-pkg3-version"]]]]')

        key = key_generator.generate_from_manifest('fake-pkg2', compiled_packages)
        expect(key).to eq('[["fake-pkg3","fake-pkg3-version"]]')
      end
    end

    context 'when package has 1-level deep transitive dependencies' do
      let(:compiled_packages) do
        [
          {
            'name' => 'fake-pkg1',
            'version' => 'fake-pkg1-version',
            'fingerprint' => 'fake-pkg1-fingerprint',
            'stemcell' => 'ubuntu-trusty/3000',
            'dependencies' => ['fake-pkg2', 'fake-pkg3']
          },
          {
            'name' => 'fake-pkg2',
            'version' => 'fake-pkg2-version',
            'fingerprint' => 'fake-pkg2-fingerprint',
            'stemcell' => 'ubuntu-trusty/3000',
            'dependencies' => []
          },
          {
            'name' => 'fake-pkg3',
            'version' => 'fake-pkg3-version',
            'fingerprint' => 'fake-pkg3-fingerprint',
            'stemcell' => 'ubuntu-trusty/3000',
            'dependencies' => []
          },
        ]
      end

      it 'should generate a dependency key' do
        key = key_generator.generate_from_manifest('fake-pkg1', compiled_packages)
        expect(key).to eq('[["fake-pkg2","fake-pkg2-version"],["fake-pkg3","fake-pkg3-version"]]')
      end
    end

    context 'given a database entry for a compiled package' do

      it 'should generate a dependency key' do

      end
    end
  end
end


