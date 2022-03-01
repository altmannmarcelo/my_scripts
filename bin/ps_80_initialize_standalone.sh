#!/bin/bash -x
. ps_common.sh 8.0

cd ${INS_DIR};
rm -rf datadir1 ;
mkdir -p datadir1 ;
rm ${INS_DIR}/keyring
cat <<EOF > my.cnf
[mysqld]
gdb
basedir = ${INS_DIR}
port = 3310
innodb_log_file_size=1073741824
datadir = ${INS_DIR}/datadir1
socket = ${INS_DIR}/datadir1/my.sock
log_error=${INS_DIR}/datadir1/error.err
pid-file=${INS_DIR}/datadir1/mysql.pid
early-plugin-load=keyring_file.so
keyring_file_data=${INS_DIR}/keyring
EOF
bin/mysqld --defaults-file=my.cnf --initialize-insecure ;
#bin/mysqld --defaults-file=my.cnf --innodb-undo-log-encrypt --innodb-redo-log-encrypt --binlog-encryption --default-table-encryption=ON &
bin/mysqld --defaults-file=my.cnf &
