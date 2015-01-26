module Bosh
  module Stemcell
    class CheckpointedRunner
      def initialize(git)
        @git = git
      end

      def validate!(first_stage)
        Validator.new.validate!(first_stage)
      end

      def run(stage)
        call(stage)
        each_next_stage(stage) do |next_stage|
          run(next_stage)
        end
      end

      def resume(stage, previous_stage = nil)
        if skip?(stage)
          each_next_stage(stage) do |next_stage|
            resume(next_stage, stage)
          end
        else
          reset_to(previous_stage) unless previous_stage.nil?
          run(stage)
        end
      end

      private

      def each_next_stage(stage)
        next_stages = stage.next_stages
        next_stages.each_with_index do |next_stage, i|
          reset_to(stage) if i > 0 #reset to parent stage before starting subsequent branches
          yield next_stage
        end

      end

      def call(stage)
        stage.call
        save_checkpoint(stage)
      end

      def skip?(stage)
        @git.log.include?(stage.name)
      end

      def reset_to(stage)
        @git.reset(@git.sha_with_message(stage.name))
      end

      def save_checkpoint(stage)
        @git.commit(stage.name)
      end

      class Validator
        def initialize
          @seen_names = Set.new
        end

        def validate!(stage)
          raise "Duplicate stage names detected (might be a cycle): #{stage.name}" if @seen_names.include?(stage.name)
          @seen_names << stage.name

          stage.next_stages.each { |next_stage| validate!(next_stage) }
        end
      end
    end
  end
end

