#!/bin/bash
function setVersion()
{
  VERSION=$1
  SRC_DIR="/work/ps/src/${VERSION}/"
  BLD_DIR="/work/ps/bld/${VERSION}/"
  INS_DIR="/work/ps/ins/${VERSION}/"
}
setVersion $1


function help()
{
  echo "BUILD_TYPE = 1 - RelWithDebInfo otherwise Debug"
  echo "MAX_PARALLEL - Define number of threads to run"
  echo "CLEAN_SUB - if we will remove submodules and start it over"
  echo "CLEAN_BLD - to remove previous cmake files"
  echo "CLEAN_INS - to remove previous install"
  echo "CLEAN     - same as CLEAN_SUB=1 CLEAN_BLD=1 CLEAN_INS=1"
  exit 1;
}
function start()
{
  CNF=$1
  GROUP_SUFIX=$2
  if [ "${GROUP_SUFIX}" = "0" ]; then
    DEFAULT_GROUP_SUFFIX=""
  else
    DEFAULT_GROUP_SUFFIX="--defaults-group-suffix=${GROUP_SUFIX}"
  fi
  bin/mysqld --defaults-file=${CNF} ${DEFAULT_GROUP_SUFFIX} &
  sleep 5
  PING_PORT=$(bin/my_print_defaults --defaults-file=${CNF} ${DEFAULT_GROUP_SUFFIX} show mysqld | grep '\-\-port')
  for i in $(seq 1 50);
  do
    ${INS_DIR}/bin/mysqladmin -u root ${PING_PORT} ping > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      echo "MySQL on ${PING_PORT:7} started"
      return 0
    else
      sleep 1
    fi
  done
  echo "MySQL on ${PING_PORT:7} NEVER started"
  return 1
}
function stop()
{
  TYPE=$1
  cd ${INS_DIR};
  if [ "${TYPE}" = "replication" ]; then
    PID1=$(cat ${INS_DIR}/repdatadir1/mysql.pid)
    PID2=$(cat ${INS_DIR}/repdatadir2/mysql.pid)
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
  else #standalone
    PID1=$(cat ${INS_DIR}/datadir1/mysql.pid )
    if [ "$?" -eq 0 ]; then
      kill $PID1
      for i in $(seq 1 15);
      do
        kill -0 $PID1 > /dev/null 2>&1
        if [ $? -eq 0 ]; then
          sleep 1
        else
          break
        fi
      done
      kill -0 $PID1 > /dev/null 2>&1
      if [ $? -eq 0 ]; then
          kill -9 $PID1
      fi
    fi
  fi
}

function clean_submodules()
{
  # check cleanup flags
  if [ -n "${CLEAN_SUB}" ] || [ -n "${CLEAN}" ]; then
    echo "Cleaning Submodules"
    cd ${SRC_DIR};
    for submodule in $(cat .gitmodules | grep path | awk -F'=' '{print $2}');
    do
      rm -rf $submodule || true;
    done
    git submodule deinit -f . || true
    git submodule init
    git submodule update
    for submodule in $(cat .gitmodules | grep path | awk -F'=' '{print $2}');
    do
      cd ${submodule}
      git submodule deinit -f . || true
      git submodule init
      git submodule update
      cd ${SRC_DIR}
    done
  fi
}
function prep_build()
{
  if [ -n "${HELP}" ]; then
    help
  fi

clean_submodules

  if [ -n "${CLEAN_BLD}" ] || [ -n "${CLEAN}" ]; then
    echo "Cleaning build dir"
    cd ${BLD_DIR};
    rm -rf *;
  fi

  if [ -n "${CLEAN_INS}" ] || [ -n "${CLEAN}" ]; then
    echo "Cleaning install dir"
    cd ${INS_DIR};
    rm -rf *;
  fi
  # end check cleanup flags


  if [ -n "${MAX_PARALLEL}" ]; then
      cpus=${MAX_PARALLEL};
  else
      cpus=`ncpus`;
  fi

  btype='Debug';
  BCOMMET='-Debug';
  if [ -n "${BUILD_TYPE}" ]; then
    if [ "${BUILD_TYPE}" = "1" ]; then
      btype='RelWithDebInfo';
      BCOMMET='';
    fi
  fi



  echo "Running build ${btype} on ${cpus} cpus"
  cd ${SRC_DIR};
  PERCONA_REVISION=$(git rev-parse --short HEAD);
  cd ${BLD_DIR};
}