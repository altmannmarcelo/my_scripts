#!/bin/bash -x
INS_DIR="/work/pxc/percona-xtradb-cluster-ins-8.0"
#export PATH=$PATH:/work/pxb/binaries/percona-xtrabackup-2.4.20-Linux-x86_64/bin/
cd ${INS_DIR};
rm -rf datadir1 datadir2 key1 key2;
mkdir -p datadir1 datadir2 key1 key2;
cat <<EOF > my.cnf
[mysqld]
core-file
wsrep_cluster_name=marcelo-altmann-pxc
basedir = ${INS_DIR}
wsrep_provider=${INS_DIR}/lib/libgalera_smm.so
pxc_encrypt_cluster_traffic=ON
early-plugin-load=keyring_file.so
#pxc_strict_mode=DISABLED
pxc_maint_transition_period=1
[mysqld.1]
port = 3308
datadir = ${INS_DIR}/datadir1
socket = ${INS_DIR}/datadir1/my.sock
wsrep_provider_options="gmcast.peer_timeout = PT3000S; evs.inactive_check_period = PT5000S; evs.suspect_timeout = PT50000S; evs.inactive_timeout = PT15000S; gmcast.listen_addr=tcp://0.0.0.0:4020; ist.recv_addr=127.0.0.1:4021;"
wsrep_sst_receive_address=127.0.0.1:4022
wsrep_cluster_address=gcomm://127.0.0.1:4020,127.0.0.1:5020
wsrep_node_address=127.0.0.1:4020
wsrep_node_name=node_80_1
log_error=${INS_DIR}/datadir1/error.err
keyring_file_data=${INS_DIR}/key1/keyringfile
pid-file=${INS_DIR}/datadir1/mysql.pid
[mysqld.2]
port = 3309
datadir = ${INS_DIR}/datadir2
socket = ${INS_DIR}/datadir2/my.sock
wsrep_provider_options="gmcast.peer_timeout = PT3000S; evs.inactive_check_period = PT5000S; evs.suspect_timeout = PT50000S; evs.inactive_timeout = PT15000S; gmcast.listen_addr=tcp://0.0.0.0:5020; ist.recv_addr=127.0.0.1:5021;"
wsrep_sst_receive_address=127.0.0.1:4022
wsrep_cluster_address=gcomm://127.0.0.1:4020,127.0.0.1:5020
wsrep_node_address=127.0.0.1:5020
wsrep_node_name=node_80_2
log_error=${INS_DIR}/datadir2/error.err
keyring_file_data=${INS_DIR}/key2/keyringfile
pid-file=${INS_DIR}/datadir2/mysql.pid
EOF
bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.1 --initialize-insecure ;
bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.1 --wsrep-new-cluster &

bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.2 --initialize-insecure;
cp datadir1/*.pem datadir2;
bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.2 &
