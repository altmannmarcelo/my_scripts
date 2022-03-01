#!/bin/bash
. pxc_common.sh 5.7

cd ${INS_DIR};
stop
sed -i 's/safe_to_bootstrap: 0/safe_to_bootstrap: 1/g' ${INS_DIR}/datadir1/grastate.dat


bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.1 --wsrep-new-cluster &

until ${INS_DIR}/bin/mysqladmin -u root -P 3306 ping
do
  sleep 1
done
bin/mysqld --defaults-file=my.cnf --defaults-group-suffix=.2 &

until ${INS_DIR}/bin/mysqladmin -u root -P 3307 ping
do
  sleep 1
done