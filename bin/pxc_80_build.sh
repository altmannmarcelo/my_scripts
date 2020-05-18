#!/bin/bash
SRC_DIR="/work/pxc/percona-xtradb-cluster-src-8.0/"
BLD_DIR="/work/pxc/percona-xtradb-cluster-bld-8.0/"
INS_DIR="/work/pxc/percona-xtradb-cluster-ins-8.0/"

function help()
{
  echo "BUILD_TYPE = 1 - RelWithDebInfo otherwise Debug"
  echo "MAX_PARALLEL - Define number of threads to run"
  echo "CLEAN_SUBMODULES - if we will remove submodules and start it over"
  echo "CLEAN_BLD - to remove previous cmake files"
  echo "CLEAN_INS - to remove previous installed files"
  exit 1;
}

if [ -n "${HELP}" ]; then
  help
fi

if [ -n "${MAX_PARALLEL}" ]; then
    cpus=${MAX_PARALLEL};
else
    cpus=`ncpus`;
fi

btype='Debug';
if [ -n "${BUILD_TYPE}" ]; then
  if [ "${BUILD_TYPE}" = "1" ]; then
    btype='RelWithDebInfo';
  fi
fi

if [ -n "${CLEAN_SUBMODULES}" ]; then
  cd ${SRC_DIR};
  rm -rf percona-xtradb-cluster-galera || true
  rm -rf wsrep-lib || true
  git submodule deinit -f . || true
  git submodule init
  git submodule update


  cd percona-xtradb-cluster-galera
  git submodule deinit -f . || true
  git submodule init
  git submodule update
  cd ../


  cd wsrep-lib/
  git submodule deinit -f . || true
  git submodule init
  git submodule update
  cd ../
  cd ${SRC_DIR}
  cd percona-xtradb-cluster-galera;
  PERCONA_REVISION=$(git rev-parse --short HEAD);
  GALERA_REVISION=$(git rev-parse --short HEAD);
  scons -j${cpus} psi=1 --config=force revno=${GALERA_REVISION}  \
      bpostatic=/usr/lib/x86_64-linux-gnu/libboost_program_options.a \
      libgalera_smm.so ;
  scons -j${cpus} --config=force revno=${GALERA_REVISION}  \
      bpostatic=/usr/lib/x86_64-linux-gnu/libboost_program_options.a \
      garb/garbd;
fi


echo "Running build ${btype} on ${cpus} cpus"

cd ${BLD_DIR};
if [ -n "${CLEAN_BLD}" ]; then
  rm -rf *;
  mkdir -p scripts/pxc_extra;
  cd scripts/pxc_extra;
  ln -s /work/pxb/binaries/percona-xtrabackup-2.4.20-Linux-x86_64/ pxb-2.4;
  ln -s /work/pxb/binaries/percona-xtrabackup-8.0.11-Linux-x86_64/ pxb-8.0;
fi
cmake ${SRC_DIR} -DBUILD_CONFIG=mysql_release \
        -DCMAKE_BUILD_TYPE=${btype} \
        -DFEATURE_SET=community \
        -DCMAKE_INSTALL_PREFIX="${INS_DIR}" \
        -DMYSQL_DATADIR="${INS_DIR}/data" \
        -DWITH_PAM=ON \
        -DWITHOUT_ROCKSDB=ON \
        -DWITHOUT_TOKUDB=ON \
        -DWITH_INNODB_MEMCACHED=ON \
        -DDOWNLOAD_BOOST=1 \
        -DWITH_PROTOBUF=bundled \
        -DWITH_RAPIDJSON=bundled \
        -DWITH_SYSTEM_LIBS=ON \
        -DWITH_ICU=bundled \
        -DWITH_LZ4=bundled \
        -DWITH_EDITLINE=bundled \
        -DWITH_LIBEVENT=bundled \
        -DCOMPILATION_COMMENT="Percona Server (GPL), Release 84.2, Revision ${PERCONA_REVISION}-debug" \
        -DWITH_ZSTD=bundled \
        -DWITH_NUMA=ON \
        -DWITH_BOOST="/work/boost" \
        -DMYSQL_SERVER_SUFFIX="" \
        -DWITH_WSREP=ON \
        -DDEBUG_EXTNAME=OFF \
        -DWITH_UNIT_TESTS=0 &&
make -j ${cpus} &&
if [ -n "${CLEAN_INS}" ]; then
  rm -rf ${INS_DIR};
fi
make -j ${cpus} install &&
if [ -n "${CLEAN_BLD}" ]; then
  cp ${SRC_DIR}/percona-xtradb-cluster-galera/libgalera_smm.so ${INS_DIR}/lib/ &&
  cp ${SRC_DIR}/percona-xtradb-cluster-galera/garb/garbd ${INS_DIR}/bin/ 
  cp -R ${BLD_DIR}/scripts/pxc_extra ${INS_DIR}/bin/;
fi