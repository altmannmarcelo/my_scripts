#!/bin/bash -x
. pxc_common.sh 8.0
# run steps necessary to prepare build
prep_build
buildGalera
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
        -DCOMPILATION_COMMENT="Percona XtraDB Cluster (GPL), Release 84.2, Revision ${PERCONA_REVISION}-debug" \
        -DWITH_ZSTD=bundled \
        -DWITH_NUMA=ON \
        -DWITH_BOOST="/work/boost" \
        -DMYSQL_SERVER_SUFFIX="" \
        -DWITH_WSREP=ON \
        -DDEBUG_EXTNAME=OFF \
        -DWITH_UNIT_TESTS=0 &&
make_install