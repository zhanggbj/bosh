require 'spec_helper'
require 'bosh/stemcell/stage'
require 'pry'

describe Bosh::Stemcell::Stage do

  it "has a name" do
    stage = Bosh::Stemcell::Stage.new(:my_name) {}
    expect(stage.name).to eq(:my_name)
  end

  it "can be called" do
    called = false

    stage = Bosh::Stemcell::Stage.new(:name) { called = true }

    stage.call

    expect(called).to eq(true)
  end

  it "can be chained" do
    second_stage = Bosh::Stemcell::Stage.new(:second_stage) {}
    third_stage = Bosh::Stemcell::Stage.new(:third_stage) {}

    first_stage = Bosh::Stemcell::Stage.new(:first_stage) {
    }.chain.next(
      second_stage
    ).next(
      third_stage
    ).done

    expect(first_stage.next_stages).to eq([second_stage])
    expect(second_stage.next_stages).to eq([third_stage])
  end

  it "can branch" do
    first_branch_first_stage = Bosh::Stemcell::Stage.new(:first_first) {}
    second_branch_first_stage = Bosh::Stemcell::Stage.new(:second_first) {}
    second_branch_second_stage = Bosh::Stemcell::Stage.new(:second_second) {}

    first_stage = Bosh::Stemcell::Stage.new(:first_stage) {
    }

    first_stage.branch(
      first_branch_first_stage,
      second_branch_first_stage.chain.next(
        second_branch_second_stage
      ).done
    )

    expect(first_stage.next_stages).to eq([first_branch_first_stage, second_branch_first_stage])
    expect(second_branch_first_stage.next_stages).to eq([second_branch_second_stage])
  end

  it "can branch in a chain" do
    second_stage = Bosh::Stemcell::Stage.new(:second_stage) {}
    first_branch_first_stage = Bosh::Stemcell::Stage.new(:first_first) {}
    second_branch_first_stage = Bosh::Stemcell::Stage.new(:second_first) {}
    second_branch_second_stage = Bosh::Stemcell::Stage.new(:second_second) {}

    first_stage = Bosh::Stemcell::Stage.new(:first_stage) {
    }.chain.next(
      second_stage
    ).branch(
      first_branch_first_stage,
      second_branch_first_stage.chain.next(
        second_branch_second_stage
      ).done
    ).done

    expect(first_stage.next_stages).to eq([second_stage])
    expect(second_stage.next_stages).to eq([first_branch_first_stage, second_branch_first_stage])
    expect(second_branch_first_stage.next_stages).to eq([second_branch_second_stage])
  end

  it "can append an array of stages" do
    second_stage = Bosh::Stemcell::Stage.new(:second_stage) {}
    third_stage = Bosh::Stemcell::Stage.new(:third_stage) {}

    first_stage = Bosh::Stemcell::Stage.new(:first_stage) {
    }.chain.append(
      [second_stage, third_stage]
    ).done

    expect(first_stage.next_stages).to eq([second_stage])
    expect(second_stage.next_stages).to eq([third_stage])
  end
end
