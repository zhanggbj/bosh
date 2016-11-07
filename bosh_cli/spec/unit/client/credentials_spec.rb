require 'spec_helper'

describe Bosh::Cli::Client::UaaCredentials do
  subject(:credentials) { described_class.new(token_provider) }
  let(:token_provider) { instance_double(Bosh::Cli::Client::Uaa::TokenProvider, token: 'bearer fake-token', refresh: nil) }
  its(:authorization_header) { is_expected.to eq('bearer fake-token') }
  its(:refresh) { is_expected.to eq(true) }
end

describe Bosh::Cli::Client::BasicCredentials do
  subject(:credentials) { described_class.new('fake-user', 'fake-pass') }
  its(:authorization_header) { is_expected.to eq('Basic ZmFrZS11c2VyOmZha2UtcGFzcw==') }
  its(:refresh) { is_expected.to eq(false) }
end
