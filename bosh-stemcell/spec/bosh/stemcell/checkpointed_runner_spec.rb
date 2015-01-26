require 'spec_helper'
require 'bosh/stemcell/checkpointed_runner'
require 'bosh/stemcell/stage'
require 'bosh/stemcell/git'

describe Bosh::Stemcell::CheckpointedRunner do

  class ActionSpy
    def initialize
      @actions = []
    end

    def actions_taken
      @actions
    end

    def run_stage(stage_name)
      @actions << "call #{stage_name}"
    end

    def commit_stage(stage_name)
      @actions << "commit #{stage_name}"
    end

    def reset_to_stage(stage_name)
      @actions << "reset to #{stage_name}"
    end
  end

  class FakeGit
    def initialize(actions_spy)
      @actions_spy = actions_spy
      @commit_messages = []
      @commits = {}
    end

    def commit(stage_name)
      git_commit(stage_name)
      @actions_spy.commit_stage(stage_name.to_s)
    end

    def log
      @commit_messages
    end

    def reset(target_sha)
      stage_name, _ = @commits.find { |_, sha| sha == target_sha }
      @actions_spy.reset_to_stage(stage_name)
    end

    def sha_with_message(stage_name)
      @commits[stage_name.to_s]
    end

    def already_ran(stage_name)
      git_commit(stage_name)
    end

    def git_commit(stage_name)
      commit_sha = SecureRandom.uuid
      @commits[stage_name.to_s] = commit_sha
      @commit_messages << stage_name.to_s
    end
  end

  let(:action_spy) {
    ActionSpy.new
  }
  let(:fake_git) {
    FakeGit.new(action_spy)
  }

  def build_stage(name)
    Bosh::Stemcell::Stage.new(name) {
      action_spy.run_stage(name)
    }
  end

  describe "#validate!" do
    it "enforces stage name uniqueness" do
      valid_first_stage = build_stage(:first_stage).chain.
        next(
        build_stage(:second_stage)
      ).done

      invalid_first_stage = build_stage(:first_stage).chain.
        next(
        build_stage(:first_stage)
      ).done

      expect {
        Bosh::Stemcell::CheckpointedRunner.new(fake_git).validate!(valid_first_stage)
      }.not_to raise_error

      expect {
        Bosh::Stemcell::CheckpointedRunner.new(fake_git).validate!(invalid_first_stage)
      }.to raise_error("Duplicate stage names detected (might be a cycle): first_stage")
    end

    it "detects cycles" do
      first_stage = build_stage(:first_stage)
      second_stage= build_stage(:second_stage)

      first_stage.next_stages = [second_stage]
      second_stage.next_stages = [first_stage]

      expect {
        Bosh::Stemcell::CheckpointedRunner.new(fake_git).validate!(first_stage)
      }.to raise_error("Duplicate stage names detected (might be a cycle): first_stage")
    end
  end

  describe "#run" do
    it "runs the stages in order and commits after each one" do
      first_stage = build_stage(:first_stage).chain.
        next(
          build_stage(:second_stage)
      ).done

      Bosh::Stemcell::CheckpointedRunner.new(fake_git).run(first_stage)

      expect(action_spy.actions_taken).to eq([
        "call first_stage",
        "commit first_stage",
        "call second_stage",
        "commit second_stage",
      ])
    end

    it "can handle multiple next stages and resets to the common parent before running other branches" do
      first_stage = build_stage(:first_stage).chain.
        branch(
        build_stage(:first_branch),
        build_stage(:second_branch).chain.
          next(
          build_stage(:second_branch_second_step)
        ).done
      ).done

      Bosh::Stemcell::CheckpointedRunner.new(fake_git).run(first_stage)

      expect(action_spy.actions_taken).to eq([
        "call first_stage",
        "commit first_stage",
        "call first_branch",
        "commit first_branch",
        "reset to first_stage",
        "call second_branch",
        "commit second_branch",
        "call second_branch_second_step",
        "commit second_branch_second_step"])
    end

    it "does not skip stages" do
      first_stage = build_stage(:first_stage).chain.
        next(
        build_stage(:second_stage)
      ).done

      fake_git.already_ran(:first_stage)

      Bosh::Stemcell::CheckpointedRunner.new(fake_git).run(first_stage)

      expect(action_spy.actions_taken).to eq(["call first_stage", "commit first_stage", "call second_stage", "commit second_stage"])
    end
  end

  describe "#resume" do
    it "skips stages if they've already been run and resets to the last one" do
      first_stage = build_stage(:first_stage).chain.
        next(
        build_stage(:second_stage)
      ).done

      fake_git.already_ran(:first_stage)

      Bosh::Stemcell::CheckpointedRunner.new(fake_git).resume(first_stage)

      expect(action_spy.actions_taken).to eq(["reset to first_stage", "call second_stage", "commit second_stage"])
    end

    it "starts from first stage if nothing run yet" do
      first_stage = build_stage(:first_stage).chain.
        next(
        build_stage(:second_stage)
      ).done

      Bosh::Stemcell::CheckpointedRunner.new(fake_git).resume(first_stage)

      expect(action_spy.actions_taken).to eq(["call first_stage", "commit first_stage", "call second_stage", "commit second_stage"])
    end
  end

  describe "integration tests" do
    let(:tmpdir) { Dir.mktmpdir }

    after { FileUtils.rm_rf(tmpdir) }

    def build_file_stage(stage_name, stages)
      Bosh::Stemcell::Stage.new(stage_name) {
        stages << stage_name
        FileUtils.touch(File.join(tmpdir, stage_name.to_s))
      }
    end

    it "works in the common cases" do
      git = Bosh::Stemcell::Git.new(tmpdir)

      stages = []

      first_stage = build_file_stage(:first, stages).
        chain.next(
          build_file_stage(:second, stages)
        ).append(
          [
            build_file_stage(:third, stages),
            build_file_stage(:fourth, stages)
          ]
        ).branch(
          build_file_stage(:first_branch, stages),
          build_file_stage(:second_branch, stages),
        ).done

      git.init

      Bosh::Stemcell::CheckpointedRunner.new(git).run(first_stage)

      expect(File.exist?(File.join(tmpdir, 'first'))).to eq(true)
      expect(File.exist?(File.join(tmpdir, 'second'))).to eq(true)
      expect(File.exist?(File.join(tmpdir, 'third'))).to eq(true)
      expect(File.exist?(File.join(tmpdir, 'fourth'))).to eq(true)
      expect(File.exist?(File.join(tmpdir, 'first_branch'))).to eq(false)
      expect(File.exist?(File.join(tmpdir, 'second_branch'))).to eq(true)

      expect(stages).to eq([
        :first, :second, :third, :fourth, :first_branch, :second_branch
      ])
    end


    it "can resume a failed run" do
      git = Bosh::Stemcell::Git.new(tmpdir)
      stages = []
      blow_up = true

      first_stage = build_file_stage(:first, stages).
        chain.next(
          build_file_stage(:second, stages)
        ).append(
          [
            Bosh::Stemcell::Stage.new(:third) {
              stages << :third
              if blow_up
                FileUtils.touch(File.join(tmpdir, 'i_failed'))
                raise 'boom'
              else
                FileUtils.touch(File.join(tmpdir, 'third'))
              end
            },
            build_file_stage(:fourth, stages)
          ]
        ).branch(
          build_file_stage(:first_branch, stages),
          build_file_stage(:second_branch, stages),
        ).done

      git.init

      expect { Bosh::Stemcell::CheckpointedRunner.new(git).run(first_stage) }.to raise_error
      blow_up = false
      Bosh::Stemcell::CheckpointedRunner.new(git).resume(first_stage)

      expect(stages).to eq([
        :first, :second, :third, :third, :fourth, :first_branch, :second_branch
      ])

      expect(File.exist?(File.join(tmpdir, 'first'))).to eq(true)
      expect(File.exist?(File.join(tmpdir, 'second'))).to eq(true)
      expect(File.exist?(File.join(tmpdir, 'i_failed'))).to eq(false)
      expect(File.exist?(File.join(tmpdir, 'third'))).to eq(true)
      expect(File.exist?(File.join(tmpdir, 'fourth'))).to eq(true)
      expect(File.exist?(File.join(tmpdir, 'first_branch'))).to eq(false)
      expect(File.exist?(File.join(tmpdir, 'second_branch'))).to eq(true)
    end
  end
end
