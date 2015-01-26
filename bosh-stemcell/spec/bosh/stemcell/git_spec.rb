require 'spec_helper'
require 'bosh/stemcell/git'
require 'tmpdir'
require 'git'

describe Bosh::Stemcell::Git do
  let(:tmpdir) { Dir.mktmpdir }
  let(:git) { Bosh::Stemcell::Git.new(tmpdir) }

  after { FileUtils.rm_rf(tmpdir) }

  def write_file(name, contents)
    File.write(File.join(tmpdir, name), contents)
  end

  def git_command(command)
    `cd #{tmpdir} && git #{command}`
  end

  describe "#init" do
    it "git inits" do
      expect {
        git.init
      }.to change {
        File.exist?(File.join(tmpdir, '.git'))
      }.from(false).to(true)
    end

    it "makes initial commit" do
      git.init
      expect(git.log).to eq(['Initial commit'])
    end
  end

  describe "#commit" do
    before { git.init }

    it "commits everything" do
      write_file('foo_file', 'foo contents')

      expect(git_command('status')).to match("foo_file")

      git.commit('commit message')

      expect(git_command('status')).not_to match("foo_file")
    end
  end

  describe "#log" do
    before { git.init }

    it "returns an array of commit messages" do
      write_file('foo_file', 'foo contents')
      git.commit('first commit')
      write_file('bar_file', 'bar contents')
      git.commit('second commit')

      expect(git.log).to eq(['Initial commit', 'first commit', 'second commit'])
    end
  end

  describe "#reset" do
    before { git.init }

    it "resets to that sha from a dirty directory" do
      write_file('foo_file', 'foo contents')

      git.commit('first commit')
      sha = Git.open(tmpdir).log.first.sha

      write_file('bar_file', 'bar contents')
      write_file('foo_file', 'new contents')
      Dir.mkdir(File.join(tmpdir, 'newdir'))

      git.reset(sha)

      expect(File.read(File.join(tmpdir, 'foo_file'))).to eq('foo contents')
      expect(File.exist?(File.join(tmpdir, 'bar_file'))).to eq(false)
      expect(Dir.exist?(File.join(tmpdir, 'newdir'))).to eq(false)
    end
  end

  describe '#delete' do
    before { git.init }

    it 'removes .git directory in git root' do
      git.delete
      expect(File.exist?(File.join(tmpdir, '.git'))).to eq(false)
    end
  end

  describe "#sha_with_message" do
    before { git.init }

    it "raises when the commit can't be found" do
      write_file('foo_file', 'foo contents')
      git.commit('commit to make the git gem happy')

      expect {
        git.sha_with_message('fake message')
      }.to raise_error "Couldn't find commit with message 'fake message'"
    end

    it "returns the commit sha that exactly matches the message" do
      write_file('foo_file', 'foo contents')
      git.commit('target_commit but before it')

      write_file('foo_file', 'new contents')
      git.commit('target_commit')
      sha = Git.open(tmpdir).log.first.sha

      write_file('foo_file', 'even newer contents')
      git.commit('target_commit but after it')

      expect(git.sha_with_message(:target_commit)).to eq(sha)
      expect(git.sha_with_message('target_commit')).to eq(sha)
    end
  end
end
