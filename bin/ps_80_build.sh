#!/bin/bash
SRC_DIR="/work/ps/percona-server-src-8.0/"
BLD_DIR="/work/ps/percona-server-bld-8.0/"
INS_DIR="/work/ps/percona-server-ins-8.0/"

#
# BUILD_TYPE = 1 - RelWithDebInfo otherwise Debug
# MAX_PARALLEL - Define number of threads to run
# CLEAN_SUBMODULES - if we will remove submodules and start it over
# CLEAN_BLD - to remove previous cmake files
#
if [ -n "${MAX_PARALLEL}" ]; then
    cpus=${MAX_PARALLEL};
else
    cpus=`ncpus`;
fi

cd ${SRC_DIR};
rev_comment=$(git rev-parse --short HEAD)

btype='Debug';
comment="-Debug"
if [ -n "${BUILD_TYPE}" ]; then
  if [ "${BUILD_TYPE}" = "1" ]; then
    btype='RelWithDebInfo';
    comment=""
  fi
fi

if [ -n "${CLEAN_SUBMODULES}" ]; then
  git submodule deinit -f . || true
  git submodule init
  git submodule update
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
        -DWITH_RAPIDJSON=bundled \
        -DWITH_SYSTEM_LIBS=ON \
        -DWITH_ICU=bundled \
        -DWITH_LZ4=bundled \
        -DWITH_LIBEVENT=bundled \
        -DCOMPILATION_COMMENT="Percona Server (GPL), Revision - ${rev_comment}${comment}" \
        -DWITH_ZSTD=bundled \
        -DWITH_NUMA=ON \
        -DWITH_BOOST="/work/boost" \
        -DMYSQL_SERVER_SUFFIX="" \
        -DDEBUG_EXTNAME=OFF \
        -DWITH_UNIT_TESTS=0 &&
make -j ${cpus} &&
make -j ${cpus} install