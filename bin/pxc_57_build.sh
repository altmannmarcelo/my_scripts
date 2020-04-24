#!/bin/bash
SRC_DIR="/work/pxc/percona-xtradb-cluster-src-5.7/"
BLD_DIR="/work/pxc/percona-xtradb-cluster-bld-5.7/"
INS_DIR="/work/pxc/percona-xtradb-cluster-ins-5.7/"

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
  rm -rf wsrep/src || true
  git submodule deinit -f . || true
  git submodule init
  git submodule update
  
  cd percona-xtradb-cluster-galera
  git submodule deinit -f . || true
  git submodule init
  git submodule update
  cd ${SRC_DIR}

  cd wsrep/src
  git submodule deinit -f . || true
  git submodule init
  git submodule update
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
        -DWITH_LZ4=bundled \
        -DWITH_EDITLINE=bundled \
        -DWITH_LIBEVENT=bundled \
        -DCOMPILATION_COMMENT="Percona Server (GPL), Release 84.2, Revision ${PERCONA_REVISION}-debug" \
        -DWITH_NUMA=ON \
        -DWITH_BOOST="/work/boost" \
        -DMYSQL_SERVER_SUFFIX="" \
        -DWITH_WSREP=ON \
        -DDEBUG_EXTNAME=OFF \
        -DWITH_UNIT_TESTS=0;
make -j ${cpus};
make -j ${cpus} install;
cp ${SRC_DIR}/percona-xtradb-cluster-galera/libgalera_smm.so ${INS_DIR}/lib/;
cp ${SRC_DIR}/percona-xtradb-cluster-galera/garb/garbd ${INS_DIR}/bin/;