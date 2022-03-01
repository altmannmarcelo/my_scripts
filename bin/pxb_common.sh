#!/bin/bash
function setVersion()
{
  VERSION=$1
  SRC_DIR="/work/pxb/src/${VERSION}/"
  BLD_DIR="/work/pxb/bld/${VERSION}/"
  INS_DIR="/work/pxb/ins/${VERSION}/"
}
setVersion $1


function help()
{
  echo "BUILD_TYPE = 1 - RelWithDebInfo otherwise Debug"
  echo "MAX_PARALLEL - Define number of threads to run"
  echo "CLEAN_BLD - to remove previous cmake files"
  echo "CLEAN_INS - to remove previous install"
  echo "CLEAN     - same as CLEAN_SUB=1 CLEAN_BLD=1 CLEAN_INS=1"
  exit 1;
}

function prep_build()
{
  if [ -n "${HELP}" ]; then
    help
  fi
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


  echo "Running build ${btype} on ${cpus} cpus"
  cd ${SRC_DIR};
  PERCONA_REVISION=$(git rev-parse --short HEAD);
  cd ${BLD_DIR};
  CMAKE_XTRA=""
  if [ -n "${ASAN}" ]; then
    if [ "${ASAN}" = "1" ]; then
      CMAKE_XTRA="${CMAKE_XTRA} -DWITH_ASAN=ON"
    fi
  fi
}
function make_install()
{
  make -j ${cpus} &&
  make -j ${cpus} install
}
