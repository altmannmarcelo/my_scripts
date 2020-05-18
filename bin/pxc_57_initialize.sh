#!/bin/bash
INS_DIR="/work/pxc/percona-xtradb-cluster-ins-5.7"
export PATH=$PATH:/work/pxb/binaries/percona-xtrabackup-2.4.20-Linux-x86_64/bin/
cd ${INS_DIR};
rm -rf datadir1 datadir2 key1 key2;
mkdir -p datadir1 datadir2 key1 key2;
cat <<EOF > my.cnf
[mysqld]
pxc_encrypt_cluster_traffic = OFF
wsrep_cluster_name=marcelo-altmann-pxc
basedir = ${INS_DIR}
wsrep_provider=${INS_DIR}/lib/libgalera_smm.so
wsrep_sst_auth=root:
early-plugin-load=keyring_file.so
[mysqld.1]
port = 3306
datadir = ${INS_DIR}/datadir1
socket = ${INS_DIR}/datadir1/my.sock
wsrep_provider_options="gmcast.peer_timeout = PT3000S; evs.inactive_check_period = PT5000S; evs.suspect_timeout = PT50000S; evs.inactive_timeout = PT15000S; gmcast.listen_addr=tcp://0.0.0.0:4010; ist.recv_addr=127.0.0.1:4011;"
wsrep_sst_receive_address=127.0.0.1:4012
wsrep_cluster_address=gcomm://127.0.0.1:4010,127.0.0.1:5010
wsrep_node_address=127.0.0.1:4010
wsrep_node_name=node_57_1
log_error=${INS_DIR}/datadir1/error.err
keyring_file_data=/key3/keyringfile
[mysqld.2]
port = 3307
datadir = ${INS_DIR}/datadir2
socket = ${INS_DIR}/datadir2/my.sock
wsrep_provider_options="gmcast.peer_timeout = PT3000S; evs.inactive_check_period = PT5000S; evs.suspect_timeout = PT50000S; evs.inactive_timeout = PT15000S; gmcast.listen_addr=tcp://0.0.0.0:5010; ist.recv_addr=127.0.0.1:5011;"
wsrep_sst_receive_address=127.0.0.1:4012
wsrep_cluster_address=gcomm://127.0.0.1:4010,127.0.0.1:5010
wsrep_node_address=127.0.0.1:5010
wsrep_node_name=node_57_2
log_error=${INS_DIR}/datadir2/error.err
keyring_file_data=${INS_DIR}/key2/keyringfile
EOF

bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.1 --initialize-insecure ;
bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.1 --wsrep-new-cluster &

bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.2 --initialize-insecure;
bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.2 &