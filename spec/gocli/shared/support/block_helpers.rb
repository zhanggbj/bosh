require 'json'

module Support
  module BlockHelpers
    def parse_blocks(source)
      Parser.new(source).data
    end

    class Parser
      def initialize(source)
        @source = source
      end

      def data
        begin
          parsed_data = JSON.parse(@source)
        rescue JSON::ParserError => e
          raise 'Be sure to pass `json: true` arg to bosh_runner.run'
        end
        parsed_data['Blocks']
      end
    end
  end
end

RSpec.configure do |config|
  config.include(Support::BlockHelpers)
end
