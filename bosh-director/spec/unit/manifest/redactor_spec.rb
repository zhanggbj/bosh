require 'spec_helper'

module Bosh::Director
  describe Redactor do

    let(:manifest_obj) do
      {
        'name' => 'test_name',
        'uuid' => '12324234234234234234',
        'env' => {
          'bosh' => {
            'one' => [1, 2, {'three' => 3}],
            'two' => 2,
            'three' => 3
          },
          'c' => 'dont-redact-me',
          'e' => 'i-am-not-secret'
        },
        'jobs' => [
          {
            'name' => "test_job",
            'properties' => {
              'a' => {
                'one' => [1, 2, {'three' => 3}],
                'two' => 2,
                'three' => 3
              },
              'c' => "redact-me\nwith
\nanother\nline",
              'e' => 'i-am-secret'
            }
          }
        ]
      }
    end

    let(:manifest_with_redaction_markers) do
      {
        'name' => 'test_name',
        'uuid' => '12324234234234234234',
        'env' => {
          'bosh' => {
            'one' => ["1<redact this!!!>", "2<redact this!!!>", {'three' => "3<redact this!!!>"}],
            'two' => "2<redact this!!!>",
            'three' => "3<redact this!!!>"
          },
          'c' => 'dont-redact-me',
          'e' => 'i-am-not-secret'
        },
        'jobs' => [
          {
            'name' => "test_job",
            'properties' => {
              'a' => {
                'one' => ["1<redact this!!!>", "2<redact this!!!>", {'three' => "3<redact this!!!>"}],
                'two' => "2<redact this!!!>",
                'three' => "3<redact this!!!>"
              },
              'c' => 'redact-me<redact this!!!>',
              'e' => 'i-am-secret<redact this!!!>'
            }
          }
        ]
      }
    end

    let (:marked_for_redaction){ Redactor.mark_properties_for_redaction(manifest_obj) }
    let (:redacted_manifest) { Redactor.redact_text_marked_for_redaction(marked_for_redaction.to_yaml)}

    describe '#mark_properties_for_redaction' do
      it "marks appropriate fields in a manifest hash for redaction" do
        expect(marked_for_redaction.to_yaml).to eq manifest_with_redaction_markers.to_yaml
      end
    end

    describe '#redact_text_marked_for_redaction' do
      it 'redacts a manifest that has been marked for redaction' do
        print marked_for_redaction.to_yaml
        expect(redacted_manifest.to_yaml).to eq({
          'name' => 'test_name',
          'uuid' => '12324234234234234234',
          'env' => {
            'bosh' => {
              'one' => ['<redacted>', '<redacted>', {'three' => '<redacted>'}],
              'two' => '<redacted>',
              'three' => '<redacted>'
            },
            'c' => 'dont-redact-me',
            'e' => 'i-am-not-secret'
          },
          'jobs' => [
            {
              'name' => "test_job",
              'properties' => {
                'a' => {
                  'one' => ['<redacted>', '<redacted>', {'three' => '<redacted>'}],
                  'two' => '<redacted>',
                  'three' => '<redacted>'
                },
                'c' => '<redacted>',
                'e' => '<redacted>'
              }
            }
          ]
        }.to_yaml)


      end

    end

      it 'inserts a manifest marker string in fields to be redacted' do

      puts "marked_for_redaction"

    # redacted_manifest = Redactor.redact_text_marked_for_redaction marked_for_redaction

        puts marked_for_redaction





    end


    context 'redact properties/env' do
      it 'redacts child nodes of properties/env hashes recursively' do
        manifest_obj = {
          'name' => 'test_name',
          'uuid' => '12324234234234234234',
          'env' => {
            'bosh' => {
              'one' => [1, 2, {'three' => 3}],
              'two' => 2,
              'three' => 3
            },
            'c' => 'dont-redact-me',
            'e' => 'i-am-not-secret'
          },
          'jobs' => [
            {
              'name' => "test_job",
              'properties' => {
                'a' => {
                  'one' => [1, 2, {'three' => 3}],
                  'two' => 2,
                  'three' => 3
                },
                'c' => 'redact-me',
                'e' => 'i-am-secret'
              }
            }
          ]
        }

        expect(described_class.redact_properties(manifest_obj)).to eq({
          'name' => 'test_name',
          'uuid' => '12324234234234234234',
          'env' => {
            'bosh' => {
              'one' => ['<redacted>', '<redacted>', {'three' => '<redacted>'}],
              'two' => '<redacted>',
              'three' => '<redacted>'
            },
            'c' => 'dont-redact-me',
            'e' => 'i-am-not-secret'
          },
          'jobs' => [
            {
              'name' => "test_job",
              'properties' => {
                'a' => {
                  'one' => ['<redacted>', '<redacted>', {'three' => '<redacted>'}],
                  'two' => '<redacted>',
                  'three' => '<redacted>'
                },
                'c' => '<redacted>',
                'e' => '<redacted>'
              }
            }
          ]
        })
      end

      context 'when properties are present at both local and global level' do
        it 'redacts properties at both levels' do
          manifest_obj = {
            'jobs' => [
              {
                'name' => "test_job",
                'properties' => {
                  'a' => {
                    'one' => [1, 2, {'three' => 3}],
                    'two' => 2,
                    'three' => 3
                  },
                  'c' => 'redact-me',
                  'e' => 'i-am-secret'
                }
              }
            ],
            'properties' => {
              'x' => {
                'x-one' => ['x1', 'x2', {'x-three' => 'x3'}],
                'x-two' => 'x2',
                'x-three' => 'x3'
              },
              'y' => 'y-redact-me',
              'z' => 'z-secret'
            }
          }

          expect(described_class.redact_properties(manifest_obj)).to eq({
            'jobs' => [
              {
                'name' => "test_job",
                'properties' => {
                  'a' => {
                    'one' => ['<redacted>', '<redacted>', {'three' => '<redacted>'}],
                    'two' => '<redacted>',
                    'three' => '<redacted>'
                  },
                  'c' => '<redacted>',
                  'e' => '<redacted>'
                }
              }
            ],
            'properties' => {
              'x' => {
                'x-one' => ['<redacted>', '<redacted>', {'x-three' => '<redacted>'}],
                'x-two' => '<redacted>',
                'x-three' => '<redacted>'
              },
              'y' => '<redacted>',
              'z' => '<redacted>'
            }
          })
        end
      end

      it 'does not redact if properties/env is not a hash' do
        manifest_obj = {
          'name' => 'test_name',
          'uuid' => '12324234234234234234',
          'env' => 'hello',
          'jobs' => [
            {
              'name' => 'test_job',
              'properties' => [
                'a',
                'b',
                'c'
              ]
            }
          ]
        }

        expect(described_class.redact_properties(manifest_obj)).to eq(manifest_obj)
      end

      it 'does not redact when redact parameter is false' do
        manifest_obj = {
          'name' => 'test_name',
          'uuid' => '12324234234234234234',
          'env' => {
            'bosh' => {
              'one' => [1, 2, {'three' => 3}],
              'two' => 2,
              'three' => 3
            },
            'c' => 'dont-redact-me',
            'e' => 'i-am-not-secret'
          },
          'jobs' => [
            {
              'name' => "test_job",
              'properties' => {
                'a' => {
                  'one' => [1, 2, {'three' => 3}],
                  'two' => 2,
                  'three' => 3
                },
                'c' => 'redact-me',
                'e' => 'i-am-secret'
              }
            }
          ]
        }

        expect(described_class.redact_properties(manifest_obj, false)).to eq({
          'name' => 'test_name',
          'uuid' => '12324234234234234234',
          'env' => {
            'bosh' => {
              'one' => [1, 2, {'three' => 3}],
              'two' => 2,
              'three' => 3
            },
            'c' => 'dont-redact-me',
            'e' => 'i-am-not-secret'
          },
          'jobs' => [
            {
              'name' => "test_job",
              'properties' => {
                'a' => {
                  'one' => [1, 2, {'three' => 3}],
                  'two' => 2,
                  'three' => 3
                },
                'c' => 'redact-me',
                'e' => 'i-am-secret'
              }
            }
          ]
        })
      end
    end
  end
end
