#!/bin/bash
for test in "$@"
do
./mtr $test
if [[ "$?" -ne "0" ]];
then
  while true; do
    read -p "Test failed. Do you want to record and copy? " yn
    case $yn in
        [Yy]* ) RECORD=1; break;;
        [Nn]* ) RECORD=0; break;;
        * ) echo "Please answer y or n.";;
    esac
  done
  if [[ ${RECORD} -eq 1 ]];
  then
    ./mtr $test --record
    cp r/${test}.result /work/ps/src/5.7/mysql-test/r/
  fi
fi
done