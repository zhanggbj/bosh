require 'spec_helper'
require 'sinatra/base'
require 'pry'

describe "UAA client" do
  before { WebMock.disable! }

  it "can fetch the login prompts from uaa" do
    fake_uaa = FakeUaa.new
    fake_uaa.prompts = {
      "username"=>["text", "Email"],
      "password"=>["password", "Password"],
      "passcode"=>["password", "One Time Code (Get one at http://localhost:8080/uaa/passcode)"]
    }
    fake_uaa.with_fake_uaa do
      uaa_client = Bosh::Cli::Client::Uaa.new({'url' => fake_uaa.url})
      expect(uaa_client.prompts).to match_array([
        Bosh::Cli::Client::Uaa::Prompt.new('username', 'text', 'Email'),
        Bosh::Cli::Client::Uaa::Prompt.new('password', 'password', 'Password'),
        Bosh::Cli::Client::Uaa::Prompt.new('passcode', 'password', 'One Time Code (Get one at http://localhost:8080/uaa/passcode)'),
      ])
    end
  end

  class FakeUaa
    attr_accessor :prompts

    def initialize
      @prompts = {}
    end

    def url
      "http://localhost:#{port}"
    end

    def with_fake_uaa
      app_thread = start_app

      yield

      stop_app(app_thread)
    end

    private

    def port
      5678
    end

    def start_app
      app_thread = Thread.new do
        $stdout.sync = true

        FakeUaaApp.set :prompts, @prompts

        FakeUaaApp.set :raise_errors, true
        FakeUaaApp.run!(port: port)
      end

      Timeout::timeout(5) do
        until FakeUaaApp.running?
          sleep 0.1
        end
      end

      app_thread
    end

    def stop_app(app_thread)
      FakeUaaApp.quit!
      Timeout::timeout(5) do
        while FakeUaaApp.running?
          sleep 0.1
        end
      end
    ensure
      app_thread.kill
    end

    class FakeUaaApp < Sinatra::Base
      get '/login' do
        content_type :json
        response = {
          "app" => {
            "version" => "2.0.3"
          },
          "createAccountLink" => "/create_account",
          "forgotPasswordLink" => "/forgot_password",
          "links" => {
            "uaa" => "http => //localhost => 8080/uaa",
            "passwd" => "/forgot_password",
            "login" => "http => //localhost => 8080/login",
            "loginPost" => "http => //localhost => 8080/uaa/login.do",
            "register" => "/create_account"},
            "entityID" => "cloudfoundry-saml-login",
            "commit_id" => "620cac2",
            "prompts" => settings.prompts,
            "idpDefinitions" => [],
            "timestamp" => "2015-02-05T15 => 16 => 38-0800"
        }
        JSON.dump(response)
      end

      get /(.*)/ do |path|
        puts "request to #{path}"
        ""
      end
    end
  end
end
