#!/bin/bash -x
. ps_common.sh 8.0
# run steps necessary to prepare build
prep_build
WITH_ROCK_DB='OFF';
if [ -n "${ROCKSDB}" ]; then
  if [ "${ROCKSDB}" = "1" ]; then
    WITH_ROCK_DB='ON';
  fi
fi
cmake ${SRC_DIR} -DBUILD_CONFIG=mysql_release \
        -DCMAKE_BUILD_TYPE=${btype} \
        -DFEATURE_SET=community \
        -DCMAKE_INSTALL_PREFIX="${INS_DIR}" \
        -DMYSQL_DATADIR="${INS_DIR}/data" \
        -DWITH_PAM=ON \
        -DWITH_ROCKSDB=${WITH_ROCK_DB} \
        -DWITH_TOKUDB=OFF \
        -DWITH_TOKUDB_BACKUP_PLUGIN=OFF \
        -DWITHOUT_TOKUDB_BACKUP_PLUGIN=ON \
        -DWITH_INNODB_MEMCACHED=ON \
        -DWITH_PROTOBUF=bundled \
        -DWITH_EDITLINE=bundled \
        -DWITH_RAPIDJSON=bundled \
        -DWITH_SYSTEM_LIBS=ON \
        -DWITH_ICU=bundled \
        -DWITH_LZ4=bundled \
        -DWITH_LIBEVENT=system \
        -DCOMPILATION_COMMENT="Percona Server (GPL), Revision ${PERCONA_REVISION}${BCOMMET}" \
        -DWITH_ZSTD=bundled \
        -DWITH_NUMA=ON \
        -DWITH_BOOST="/work/boost" \
        -DMYSQL_SERVER_SUFFIX="" \
        -DDEBUG_EXTNAME=OFF \
        -DWITH_LOCK_ORDER=ON \
	-DCOMPRESS_DEBUG_SECTIONS=ON \
  -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-O0 -g" \
        -DWITH_UNIT_TESTS=0 &&

make -j ${cpus} &&
make -j ${cpus} install

# Other flags
# -DREPRODUCIBLE_BUILD=ON  - ommit buildID
