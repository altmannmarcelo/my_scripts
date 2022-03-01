#!/bin/bash -x
. ps_common.sh 8.0

cd ${INS_DIR};
rm -rf repdatadir1 repdatadir2 ;
mkdir -p repdatadir1 repdatadir2;
cat <<EOF > repmy.cnf
[mysqld]
basedir = ${INS_DIR}
log_error_verbosity=3
[mysqld.1]
port = 3410
datadir = ${INS_DIR}/repdatadir1
socket = ${INS_DIR}/repdatadir1/my.sock
log_error=${INS_DIR}/repdatadir1/error.err
pid-file=${INS_DIR}/repdatadir1/mysql.pid
server-id=1
[mysqld.2]
port = 3411
datadir = ${INS_DIR}/repdatadir2
socket = ${INS_DIR}/repdatadir2/my.sock
log_error=${INS_DIR}/repdatadir2/error.err
pid-file=${INS_DIR}/repdatadir2/mysql.pid
server-id=2
EOF
bin/mysqld --defaults-file=repmy.cnf --defaults-group-suffix=.1 --initialize-insecure ;
bin/mysqld --defaults-file=repmy.cnf --defaults-group-suffix=.1 &

bin/mysqld --defaults-file=repmy.cnf --defaults-group-suffix=.2 --initialize-insecure;
bin/mysqld --defaults-file=repmy.cnf --defaults-group-suffix=.2 &
sleep 5
bin/mysql -h 127.1 -P 3411 -e "CHANGE MASTER TO MASTER_HOST='127.0.0.1', MASTER_USER='root', MASTER_PORT=3410, GET_MASTER_PUBLIC_KEY=1;START SLAVE;"