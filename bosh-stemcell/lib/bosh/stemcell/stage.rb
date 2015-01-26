module Bosh
  module Stemcell
    class Stage #TODO: pick a name that doesn't collide with stemcell_builder/stages
      def initialize(name, &blk)
        @name = name
        @blk = blk
        @next_stages = []
      end

      attr_accessor :next_stages

      def branch(*next_stages)
        @next_stages = next_stages
      end

      def chain
        ChainableStage.new(self, self)
      end

      def call
        @blk.call
      end

      def name
        @name.to_s
      end
    end
  end

  class ChainableStage
    def initialize(first_stage, stage)
      @first_stage = first_stage
      @stage = stage
    end

    def next(next_stage)
      @stage.next_stages = [next_stage]
      ChainableStage.new(@first_stage, next_stage)
    end

    # append takes an array of stages and adds it to the chain
    def append(stages)
      last_stage_so_far = @stage
      stages.each do |stage|
        last_stage_so_far.next_stages = [stage]
        last_stage_so_far = stage
      end
      ChainableStage.new(@first_stage, last_stage_so_far)
    end

    def branch(*stages)
      @stage.branch(*stages)
      ChainableStage.new(@first_stage, nil) #can't chain off of a branch
    end

    def done
      @first_stage
    end
  end
end
