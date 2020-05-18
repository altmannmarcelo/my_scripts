#!/bin/bash
INS_DIR="/work/pxc/percona-xtradb-cluster-ins-8.0"
#export PATH=$PATH:/work/pxb/binaries/percona-xtrabackup-2.4.20-Linux-x86_64/bin/
cd ${INS_DIR};
PID1=$(cat ${INS_DIR}/datadir1/mysql.pid)
PID2=$(cat ${INS_DIR}/datadir2/mysql.pid)
kill $PID2
kill $PID1

sleep 5
kill -0 $PID2
if [ $? -ne 0 ]; then
    kill -9 $PID2
fi

kill -0 $PID1
if [ $? -ne 0 ]; then
    kill -9 $PID1
fi
sed -i 's/safe_to_bootstrap: 0/safe_to_bootstrap: 1/g' ${INS_DIR}/datadir1/grastate.dat

bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.1 --wsrep-new-cluster &

until ${INS_DIR}/bin/mysqladmin -u root -P 3308 ping
do
  sleep 1
done
bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.2 &

until ${INS_DIR}/bin/mysqladmin -u root -P 3309 ping
do
  sleep 1
done