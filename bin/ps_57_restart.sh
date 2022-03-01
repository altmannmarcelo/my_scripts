#!/bin/bash
. ps_common.sh 5.7

cd ${INS_DIR};
PID1=$(cat ${INS_DIR}/datadir1/mysql.pid)
kill $PID1

sleep 5
kill -0 $PID1
if [ $? -ne 0 ]; then
    kill -9 $PID1
fi
bin/mysqld --defaults-file=my.cnf &
sleep 3
until ${INS_DIR}/bin/mysqladmin -u root -P 3311 ping
do
  sleep 1
done