#!/bin/bash -x
. ps_common.sh 5.7

cd ${INS_DIR};
rm -rf repdatadir1 repdatadir2 ;
mkdir -p repdatadir1 repdatadir2;
cat <<EOF > repmy.cnf
[mysqld]
basedir = ${INS_DIR}
log-bin
binlog_format=STATEMENT
plugin-load = "audit_log=audit_log.so"
audit_log_rotate_on_size = 200M
audit_log_rotations = 5
audit_log_handler = FILE
audit_log_format = "csv"
#audit_log_exclude_accounts = 'wdadmin@%.wd,ptadmin@%.wd,wsadmin@%.wd,\`system user\`,rsandbox@localhost'
max_allowed_packet=1G
relay_log_info_repository=TABLE
[mysqld.1]
port = 3408
datadir = ${INS_DIR}/repdatadir1
socket = ${INS_DIR}/repdatadir1/my.sock
log_error=${INS_DIR}/repdatadir1/error.err
pid-file=${INS_DIR}/repdatadir1/mysql.pid
server-id=1
[mysqld.2]
port = 3409
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
bin/mysql -h 127.1 -P 3409 -e "CHANGE MASTER TO MASTER_HOST='127.0.0.1', MASTER_USER='root', MASTER_PORT=3408; START SLAVE"