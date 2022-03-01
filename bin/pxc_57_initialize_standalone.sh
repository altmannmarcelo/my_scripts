#!/bin/bash -x
INS_DIR="/work/pxc/ins/5.7"
XB_LOCATION="/work/pxb/binaries/percona-xtrabackup-2.4.20-Linux-x86_64/"
export PATH=$PATH:$XB_LOCATION/bin/
cd ${INS_DIR};
if [ -z "${NUMBER_OF_NODES}" ]; then
  NUMBER_OF_NODES=2
fi
BASE_PORT=3400
cat <<EOF > my.cnf
[xtrabackup]
xtrabackup-plugin-dir=${XB_LOCATION}/lib

[mysqld]
pxc_encrypt_cluster_traffic = ON
wsrep_cluster_name=marcelo-altmann-pxc
basedir = ${INS_DIR}
wsrep_provider=${INS_DIR}/lib/libgalera_smm.so
wsrep_sst_auth=root:
early-plugin-load=keyring_file.so
plugin-load = "audit_log=audit_log.so"
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
#wsrep_provider_options="gmcast.peer_timeout = PT3000S; evs.inactive_check_period = PT5000S; evs.suspect_timeout = PT50000S; evs.inactive_timeout = PT15000S; gmcast.listen_addr=tcp://0.0.0.0:$((BASE_PORT + i + NUMBER_OF_NODES)); ist.recv_addr=127.0.0.1:$((BASE_PORT + i + NUMBER_OF_NODES * 2));"
wsrep_provider_options="gmcast.listen_addr=tcp://0.0.0.0:$((BASE_PORT + i + NUMBER_OF_NODES)); ist.recv_addr=127.0.0.1:$((BASE_PORT + i + NUMBER_OF_NODES * 2));"
wsrep_sst_receive_address=127.0.0.1:$((BASE_PORT + i + NUMBER_OF_NODES*3))
EOF
CLUSTER_ADDRESS=""
for ((b=1; b<=NUMBER_OF_NODES; b++))
do
  CLUSTER_ADDRESS="${CLUSTER_ADDRESS}127.0.0.1:$((BASE_PORT + b + NUMBER_OF_NODES)),"
done
cat <<EOF >> my.cnf
wsrep_cluster_address=gcomm://${CLUSTER_ADDRESS::-1}
wsrep_node_address=127.0.0.1:$((BASE_PORT + b + NUMBER_OF_NODES))
wsrep_node_name=node_57_${i}
log_error=${INS_DIR}/datadir${i}/error.err
keyring_file_data=${INS_DIR}/key${i}/keyringfile
pid-file=${INS_DIR}/datadir${i}/mysql.pid

EOF
done
for ((i=1; i<=NUMBER_OF_NODES; i++))
do
  bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.${i} --initialize-insecure ;
  if [ ${i} -eq "1" ]; then
    bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.1 --wsrep-new-cluster &
  fi
done

for ((i=2; i<=NUMBER_OF_NODES; i++))
do
  cp datadir1/*.pem datadir${i}/
  bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.${i} &
  sleep $((NUMBER_OF_NODES * 2))
done

