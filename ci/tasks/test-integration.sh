#!/usr/bin/env bash

set -e

source bosh-src/ci/tasks/utils.sh

check_param RUBY_VERSION
check_param DB

echo "Starting $DB..."
case "$DB" in
  mysql)
    mv /var/lib/mysql /var/lib/mysql-src
    mkdir /var/lib/mysql
    mount -t tmpfs -o size=512M tmpfs /var/lib/mysql
    mv /var/lib/mysql-src/* /var/lib/mysql/

    sudo service mysql start
    ;;
  postgresql)
    export PATH=/usr/lib/postgresql/9.4/bin:$PATH

    mkdir /tmp/postgres
    mount -t tmpfs -o size=512M tmpfs /tmp/postgres
    mkdir /tmp/postgres/data
    chown postgres:postgres /tmp/postgres/data

    su postgres -c '
      export PATH=/usr/lib/postgresql/9.4/bin:$PATH
      export PGDATA=/tmp/postgres/data
      export PGLOGS=/tmp/log/postgres
      mkdir -p $PGDATA
      mkdir -p $PGLOGS
      initdb -U postgres -D $PGDATA
      pg_ctl start -l $PGLOGS/server.log -o "-N 400"
    '
    ;;
  *)
    echo "Usage: DB={mysql|postgresql} $0 {commands}"
    exit 1
esac

source /etc/profile.d/chruby.sh
chruby $RUBY_VERSION

cd bosh-src

print_git_state

bundle install --local

export BOSH_CLI_SILENCE_SLOW_LOAD_WARNING=true

bundle exec rake --trace spec:integration
