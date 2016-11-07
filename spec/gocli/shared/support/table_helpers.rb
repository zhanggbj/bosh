require 'json'

module Support
  module TableHelpers
    def table(source)
      Parser.new(source).data
    end

    class Parser
      def initialize(source)
        @source = source
      end

      def data
        begin
          table_data = JSON.parse(@source)
        rescue JSON::ParserError => e
          raise 'Be sure to pass `json: true` arg to bosh_runner.run'
        end

        table_entries = []

        table_data['Tables'].each do |table|
          head = table['Header']

          table_rows = table['Rows'] || []
          table_entries += table_rows.map { |row| Hash[head.zip(row)] } if head
        end

        table_entries
      end
    end
  end
end

RSpec.configure do |config|
  config.include(Support::TableHelpers)
end
