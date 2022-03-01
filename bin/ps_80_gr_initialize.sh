#!/bin/bash -x
INS_DIR="/work/ps/ins/8.0"
cd ${INS_DIR};

function wait_for_mysql_to_start()
{
  PORT=$1
  MYSQLADMIN="mysqladmin -h 127.1 -u root -P${PORT} ping"
  while : ; do
    eval $MYSQLADMIN
    [[ $? -ne 0 ]] || break
    sleep 2
  done
}
function configure_gr()
{
  PORT=$1
  MYSQL="mysql -h 127.1 -u root -P${PORT}"
  ${MYSQL} -e "SET SQL_LOG_BIN=0;
  CREATE USER rpl_user@'localhost' IDENTIFIED BY 'password' REQUIRE SSL;
  GRANT REPLICATION SLAVE ON *.* TO rpl_user@'localhost';
  GRANT BACKUP_ADMIN ON *.* TO rpl_user@'localhost';
  FLUSH PRIVILEGES;
  SET SQL_LOG_BIN=1;
  CHANGE MASTER TO MASTER_USER='rpl_user', MASTER_PASSWORD='password' FOR CHANNEL 'group_replication_recovery';"
}
if [ -z "${NUMBER_OF_NODES}" ]; then
  NUMBER_OF_NODES=2
fi
BASE_PORT=3800
cat <<EOF > my.cnf
[mysqld]
disabled_storage_engines="MyISAM,BLACKHOLE,FEDERATED,ARCHIVE,MEMORY"
basedir = ${INS_DIR}
gtid_mode=ON
enforce_gtid_consistency=ON
binlog_checksum=NONE           # Not needed from 8.0.21
plugin_load_add='group_replication.so'
group_replication_group_name="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
group_replication_start_on_boot=off
group_replication_bootstrap_group= off
group_replication_recovery_use_ssl=ON
group_replication_recovery_get_public_key=ON

innodb_flush_log_at_trx_commit  = 0
innodb_flush_method             = O_DIRECT
innodb_file_per_table           = 1
innodb_autoinc_lock_mode=2
EOF

for ((i=1; i<=NUMBER_OF_NODES; i++))
do
  rm -rf datadir${i} key${i}
  mkdir datadir${i} key${i}
cat <<EOF >> my.cnf
[mysqld.${i}]
server-id=${i}
port = $((BASE_PORT + i))
datadir = ${INS_DIR}/datadir${i}
socket = ${INS_DIR}/datadir${i}/my.sock

group_replication_local_address= "127.0.0.1:$((BASE_PORT + i + NUMBER_OF_NODES * 2))"
EOF
CLUSTER_ADDRESS=""
for ((b=1; b<=NUMBER_OF_NODES; b++))
do
  CLUSTER_ADDRESS="${CLUSTER_ADDRESS}127.0.0.1:$((BASE_PORT + b + NUMBER_OF_NODES * 2)),"
done
cat <<EOF >> my.cnf
group_replication_group_seeds= "${CLUSTER_ADDRESS::-1}"
log_error=${INS_DIR}/datadir${i}/error.err
pid-file=${INS_DIR}/datadir${i}/mysql.pid
EOF
done
for ((i=1; i<=NUMBER_OF_NODES; i++))
do
  bin/mysqld --basedir=${INS_DIR} --datadir=${INS_DIR}/datadir${i} --log_error=${INS_DIR}/datadir${i}/error.err --initialize-insecure ;
done

for ((i=1; i<=NUMBER_OF_NODES; i++))
do
  bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.${i} &
  wait_for_mysql_to_start $((BASE_PORT + i))
  configure_gr $((BASE_PORT + i))
  MYSQL="mysql -h 127.1 -u root -P$((BASE_PORT + i))"
  if [[ ${i} -eq 1 ]];
  then
    $MYSQL -e "SET GLOBAL group_replication_bootstrap_group=ON;
    START GROUP_REPLICATION USER='rpl_user', PASSWORD='password';
    SET GLOBAL group_replication_bootstrap_group=OFF;"
  else
    $MYSQL -e "START GROUP_REPLICATION USER='rpl_user', PASSWORD='password';"
  fi
done

