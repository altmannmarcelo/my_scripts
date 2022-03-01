#!/bin/bash
. pxb_common.sh 2.4
# run steps necessary to prepare build
prep_build
cd ${INS_DIR}/xtrabackup-test
for server in /work/ps/ins/5.6 /work/ps/ins/5.7 /work/pxc/ins/5.7 /work/binaries/mysql/5.7.31 /work/binaries/mysql/5.6.49;
do
  rm server
  ln -s ${server} server
  log=$(echo ${server} | sed 's/\//_/g')
  echo "================= Testing with: ${server} ================="
  ./run.sh -f > ${log}.out
  echo "================= DONE - Testing with: ${server} ================="
done