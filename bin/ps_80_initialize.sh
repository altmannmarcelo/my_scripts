#!/bin/bash -x
INS_DIR="/work/ps/percona-server-ins-8.0"
cd ${INS_DIR};
rm -rf datadir1 ;
mkdir -p datadir1 ;
cat <<EOF > my.cnf
[mysqld]
basedir = ${INS_DIR}
port = 3310
datadir = ${INS_DIR}/datadir1
socket = ${INS_DIR}/datadir1/my.sock
log_error=${INS_DIR}/datadir1/error.err
EOF
bin/mysqld --defaults-file=my.cnf --initialize-insecure ;
bin/mysqld --defaults-file=my.cnf &
