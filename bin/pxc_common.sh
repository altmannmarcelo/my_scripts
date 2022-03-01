#!/bin/bash
function setVersion()
{
  VERSION=$1
  SRC_DIR="/work/pxc/src/${VERSION}/"
  BLD_DIR="/work/pxc/bld/${VERSION}/"
  INS_DIR="/work/pxc/ins/${VERSION}/"
  if [ ${VERSION} == "5.7" ]; then
    export PATH=$PATH:/work/pxb/binaries/percona-xtrabackup-2.4.20-Linux-x86_64/bin/
  fi
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
function buildGalera()
{
  cd ${SRC_DIR}
  cd percona-xtradb-cluster-galera;
  PERCONA_REVISION=$(git rev-parse --short HEAD);
  GALERA_REVISION=$(git rev-parse --short HEAD);
  scons -j${cpus} ${scons_debug} psi=1 --config=force revno=${GALERA_REVISION}  \
      bpostatic=/usr/lib/x86_64-linux-gnu/libboost_program_options.a \
      libgalera_smm.so ;
  if [ $? -ne 0 ]; then
    exit 1;
  fi
  scons -j${cpus} ${scons_debug} --config=force revno=${GALERA_REVISION}  \
      bpostatic=/usr/lib/x86_64-linux-gnu/libboost_program_options.a \
      garb/garbd;
  if [ $? -ne 0 ]; then
    exit 1;
  fi
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
  cd ${INS_DIR};
  PID1=$(cat ${INS_DIR}/datadir1/mysql.pid )
  PID2=$(cat ${INS_DIR}/datadir2/mysql.pid )
  if [ "x$PID1" != "x" ] && [ "x$PID1" != "x" ]; then
    kill $PID2
    kill $PID1
    for i in $(seq 1 30);
    do
      kill -0 $PID2 > /dev/null 2>&1
      if [ $? -eq 0 ]; then
        sleep 1
      else
        break
      fi
    done
    kill -0 $PID2 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      kill -9 $PID2
    fi
    for i in $(seq 1 30);
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
  else
    echo "Cannot find PID1 or PID2"
    exit 1;
  fi
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
  scons_debug="-Q debug=1";
  if [ -n "${BUILD_TYPE}" ]; then
    if [ "${BUILD_TYPE}" = "1" ]; then
      btype='RelWithDebInfo';
      BCOMMET='';
      scons_debug="";
    fi
  fi

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
    cd ${SRC_DIR}
    cd percona-xtradb-cluster-galera;
    if [ -n "${INCREASE_TIMEOUT}" ]; then
      git checkout gcomm/src/defaults.cpp;
      printf 'diff --git a/gcomm/src/defaults.cpp b/gcomm/src/defaults.cpp
index 927ae998..8b1d41a3 100644
--- a/gcomm/src/defaults.cpp
+++ b/gcomm/src/defaults.cpp
@@ -21,14 +21,14 @@ namespace gcomm
     std::string const Defaults::GMCastTcpPort           = BASE_PORT_DEFAULT;
     std::string const Defaults::GMCastSegment           = "0";
     std::string const Defaults::GMCastTimeWait          = "PT5S";
-    std::string const Defaults::GMCastPeerTimeout       = "PT3S";
+    std::string const Defaults::GMCastPeerTimeout       = "PT3000S";
     std::string const Defaults::EvsViewForgetTimeout    = "PT24H";
     std::string const Defaults::EvsViewForgetTimeoutMin = "PT1S";
-    std::string const Defaults::EvsInactiveCheckPeriod  = "PT0.5S";
-    std::string const Defaults::EvsSuspectTimeout       = "PT5S";
-    std::string const Defaults::EvsSuspectTimeoutMin    = "PT0.1S";
-    std::string const Defaults::EvsInactiveTimeout      = "PT15S";
-    std::string const Defaults::EvsInactiveTimeoutMin   = "PT0.1S";
+    std::string const Defaults::EvsInactiveCheckPeriod  = "PT5000S";
+    std::string const Defaults::EvsSuspectTimeout       = "PT50000S";
+    std::string const Defaults::EvsSuspectTimeoutMin    = "PT1S";
+    std::string const Defaults::EvsInactiveTimeout      = "PT15000S";
+    std::string const Defaults::EvsInactiveTimeoutMin   = "PT1S";
     std::string const Defaults::EvsRetransPeriod        = "PT1S";
     std::string const Defaults::EvsRetransPeriodMin     = "PT0.1S";
     std::string const Defaults::EvsJoinRetransPeriod    = "PT1S";
' | git apply
    fi
  fi

  if [ -n "${CLEAN_BLD}" ] || [ -n "${CLEAN}" ]; then
    echo "Cleaning build dir"
    cd ${BLD_DIR};
    rm -rf *;
    if [ "${VERSION}" = "8.0" ]; then
      mkdir -p scripts/pxc_extra;
      cd scripts/pxc_extra;
      ln -s /slow/binaries/pxb/percona-xtrabackup-2.4.24-Linux-x86_64.glibc2.12 pxb-2.4;
      ln -s /slow/binaries/pxb/percona-xtrabackup-8.0.26-18-Linux-x86_64.glibc2.17 pxb-8.0;
    fi
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
}
function make_install()
{
  make -j ${cpus} &&
  make -j ${cpus} install &&
  cp ${SRC_DIR}/percona-xtradb-cluster-galera/libgalera_smm.so ${INS_DIR}/lib/ &&
  cp ${SRC_DIR}/percona-xtradb-cluster-galera/garb/garbd ${INS_DIR}/bin/ &&
  if [ -n "${CLEAN_BLD}" ] || [ -n "${CLEAN_INS}" ] || [ -n "${CLEAN_SUB}" ] || [ -n "${CLEAN}" ]; then
    if [ "${VERSION}" = "8.0" ]; then
      cp -R ${BLD_DIR}/scripts/pxc_extra ${INS_DIR}/bin/;
    fi
  fi
}
