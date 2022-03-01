#!/bin/bash
. ps_common.sh 5.6

cd ${INS_DIR};
rm -rf datadir1 ;
mkdir -p datadir1 ;
cat <<EOF > my.cnf
[mysqld]
basedir = ${INS_DIR}
port = 3312
datadir = ${INS_DIR}/datadir1
socket = ${INS_DIR}/datadir1/my.sock
log_error=${INS_DIR}/datadir1/error.err
pid-file=${INS_DIR}/datadir1/mysql.pid
EOF
scripts/mysql_install_db --defaults-file=my.cnf
#bin/mysqld --defaults-file=my.cnf --initialize-insecure ;
bin/mysqld --defaults-file=my.cnf &
