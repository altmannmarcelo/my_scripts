#!/bin/bash
. ps_common.sh 5.7

cd ${INS_DIR};
rm -rf datadir1 ;
mkdir -p datadir1 ;
cat <<EOF > my.cnf
[mysqld]
basedir = ${INS_DIR}
port = 3311
datadir = ${INS_DIR}/datadir1
socket = ${INS_DIR}/datadir1/my.sock
log_error=${INS_DIR}/error.err
pid-file=${INS_DIR}/datadir1/mysql.pid
ssl=0
#early-plugin-load=keyring_file.so
#keyring_file_data=${INS_DIR}/keyring
EOF
bin/mysqld --defaults-file=my.cnf --initialize-insecure ;
bin/mysqld --defaults-file=my.cnf &
