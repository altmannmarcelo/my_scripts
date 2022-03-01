#!/bin/bash -x
INS_DIR="/work/pxc/ins/8.0"
#export PATH=$PATH:/work/pxb/binaries/percona-xtrabackup-2.4.20-Linux-x86_64/bin/
export PATH=$PATH:/work/pxb/ins/8.0/bin/
cd ${INS_DIR};
rm -rf datadir1 datadir2 datadir3 key1 key2 key3;
mkdir -p datadir1 datadir2 datadir3 key1 key2 key3;
TIMEOUTS="gmcast.peer_timeout = PT30S; evs.inactive_check_period = PT1S; evs.suspect_timeout = PT15S; evs.inactive_timeout = PT30S;"
cat <<EOF > my.cnf
[mysqld]
core-file
wsrep_cluster_name=marcelo-altmann-pxc
basedir = ${INS_DIR}
wsrep_provider=${INS_DIR}/lib/libgalera_smm.so
wsrep_cluster_address=gcomm://127.0.0.1:4020,127.0.0.1:5020,127.0.0.1:6020
pxc_encrypt_cluster_traffic=OFF
#early-plugin-load=keyring_file.so
#pxc_strict_mode=DISABLED
pxc_maint_transition_period=1
enforce-gtid-consistency
gtid-mode=ON
binlog_format=ROW
default_storage_engine=InnoDB

innodb_flush_log_at_trx_commit  = 0
innodb_flush_method             = O_DIRECT
innodb_file_per_table           = 1
innodb_autoinc_lock_mode=2
log-bin
log_slave_updates=ON
log_error_verbosity=3
[mysqld.1]
port = 3307
datadir = ${INS_DIR}/datadir1
socket = ${INS_DIR}/datadir1/my.sock
wsrep_provider_options="gcache.size = 12M; gcache.page_size=64M; ${TIMEOUTS} gmcast.listen_addr=tcp://0.0.0.0:4020; ist.recv_addr=127.0.0.1:4021;"
wsrep_sst_receive_address=127.0.0.1:4022
wsrep_node_address=127.0.0.1:4020
wsrep_node_name=node_80_1
log_error=${INS_DIR}/datadir1/error.err
#keyring_file_data=${INS_DIR}/key1/keyringfile
pid-file=${INS_DIR}/datadir1/mysql.pid
[mysqld.2]
port = 3308
datadir = ${INS_DIR}/datadir2
socket = ${INS_DIR}/datadir2/my.sock
wsrep_provider_options="gcache.size = 12M; gcache.page_size=64M; ${TIMEOUTS} gmcast.listen_addr=tcp://0.0.0.0:5020; ist.recv_addr=127.0.0.1:5021;"
wsrep_sst_receive_address=127.0.0.1:4022
wsrep_node_address=127.0.0.1:5020
wsrep_node_name=node_80_2
log_error=${INS_DIR}/datadir2/error.err
#keyring_file_data=${INS_DIR}/key2/keyringfile
pid-file=${INS_DIR}/datadir2/mysql.pid
[mysqld.3]
port = 3309
datadir = ${INS_DIR}/datadir3
socket = ${INS_DIR}/datadir3/my.sock
wsrep_provider_options="gcache.size = 12M; gcache.page_size=64M; ${TIMEOUTS} gmcast.listen_addr=tcp://0.0.0.0:6020; ist.recv_addr=127.0.0.1:6021;"
wsrep_sst_receive_address=127.0.0.1:4023
wsrep_node_address=127.0.0.1:6020
wsrep_node_name=node_80_3
log_error=${INS_DIR}/datadir3/error.err
#keyring_file_data=${INS_DIR}/key3/keyringfile
pid-file=${INS_DIR}/datadir3/mysql.pid
[sst]
transferfmt=nc
#streamfmt=tar
sst-initial-timeout=600
EOF
bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.1 --initialize-insecure ;
RR_DIR=${INS_DIR}/rr/$(date +"%Y_%m-%d_%H_%M_%S")
mkdir ${RR_DIR}
RR_COMMAND="rr record --no-syscall-buffer --no-file-cloning --no-read-cloning"
if [ -n "${WITH_RR}" ]; then
  RR_COMMAND_N1="${RR_COMMAND} -o ${RR_DIR}/node1"
else
  RR_COMMAND_N1=""
fi
${RR_COMMAND_N1} bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.1 --wsrep-new-cluster &

bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.2 --initialize-insecure;
bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.3 --initialize-insecure;
cp datadir1/*.pem datadir2;
cp datadir1/*.pem datadir3;
if [ -n "${WITH_RR}" ]; then
  sleep 10
  RR_COMMAND_N2="${RR_COMMAND} -o ${RR_DIR}/node2"
else
RR_COMMAND_N2=""
fi
${RR_COMMAND_N2} bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.2 &

if [ -n "${WITH_RR}" ]; then
  sleep 10
  RR_COMMAND_N3="${RR_COMMAND} -o ${RR_DIR}/node3"
else
RR_COMMAND_N3=""
fi

${RR_COMMAND_N3} bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.3 &
