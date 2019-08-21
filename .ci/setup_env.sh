#!/usr/bin/env bash
# set -e

# -------------------------------------
# Cassandra cluster
# -------------------------------------
if [[ "$KONG_TEST_DATABASE" == "cassandra" ]]; then
  echo "Setting up Cassandra"
  docker run -d --name=cassandra --rm -p 7199:7199 -p 7000:7000 -p 9160:9160 -p 9042:9042 cassandra:${CASSANDRA:-3.9}
  grep -q 'Created default superuser role' <(docker logs -f cassandra)
fi

# -------------------------------------
# Postgres Database
# -------------------------------------
if [[ "$KONG_TEST_DATABASE" == "postgres" ]]; then
  echo "Setting up Postgres"
  docker run -d --name=postgres --rm -p 5432:5432 postgres:${POSTGRES:-9}
  grep -q 'Created default superuser role' <(docker logs -f cassandra)
fi

# -------------------
# Install Test::Nginx
# -------------------
if [[ "$TEST_SUITE" == "pdk" ]]; then
  wget -O $HOME/bin/cpanm https://cpanmin.us
  echo "Installing CPAN dependencies..."
  cpanm --notest Test::Nginx &> build.log || (cat build.log && exit 1)
  cpanm --notest --local-lib=$TRAVIS_BUILD_DIR/perl5 local::lib && eval $(perl -I $TRAVIS_BUILD_DIR/perl5/lib/perl5/ -Mlocal::lib)
fi

# ----------------
# Run gRPC server |
# ----------------
if [[ "$TEST_SUITE" =~ integration|dbless|plugins ]]; then
  docker run -d --name grpcbin -p 15002:9000 -p 15003:9001 moul/grpcbin
fi

nginx -V
resty -V
luarocks --version
openssl version
