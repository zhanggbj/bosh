require 'git'

module Bosh
  module Stemcell
    class Git
      def initialize(git_dir)
        @git_dir = git_dir
      end

      def init
        ::Git.init(@git_dir)
        FileUtils.touch(File.join(@git_dir, 'initial-git-file'))
        commit('Initial commit')
      end

      def commit(message)
        git = ::Git.open(@git_dir)
        git.add(all: true)
        git.commit(message)
      end

      def log
        git = ::Git.open(@git_dir)
        git.log.map { |commit| commit.message }.reverse
      end

      def reset(sha)
        git = ::Git.open(@git_dir)
        git.reset_hard(sha)
        git.clean(force: true, d: true)
      end

      def delete
        FileUtils.rm_rf(File.join(@git_dir, '.git'))
      end

      def sha_with_message(message)
        git = ::Git.open(@git_dir)

        commit = git.log.find { |commit| commit.message == message.to_s }
        raise "Couldn't find commit with message '#{message}'" if commit.nil?

        commit.sha
      end
    end
  end
end
