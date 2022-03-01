#!/bin/bash -x
. ps_common.sh 5.7
# run steps necessary to prepare build
prep_build
#export CXX=${CXX:-clang++-9}
#export CC=${CC:-clang-9}
cd ${BLD_DIR};
cmake ${SRC_DIR} -DBUILD_CONFIG=mysql_release \
        -DCMAKE_BUILD_TYPE=${btype} \
        -DFEATURE_SET=community \
        -DCMAKE_INSTALL_PREFIX="${INS_DIR}" \
        -DMYSQL_DATADIR="${INS_DIR}/data" \
        -DWITH_PAM=ON \
        -DWITH_ROCKSDB=OFF \
        -DWITH_TOKUDB=OFF \
        -DWITH_INNODB_MEMCACHED=ON \
        -DDOWNLOAD_BOOST=1 \
        -DWITH_PROTOBUF=bundled \
        -DWITH_LZ4=bundled \
        -DWITH_EDITLINE=bundled \
        -DWITH_LIBEVENT=bundled \
        -DCOMPILATION_COMMENT="Percona Server (GPL), Revision ${PERCONA_REVISION}${BCOMMET}" \
        -DWITH_NUMA=ON \
        -DWITH_BOOST="/work/boost" \
        -DMYSQL_SERVER_SUFFIX="" \
        -DDEBUG_EXTNAME=OFF \
        -DWITH_UNIT_TESTS=1;
        #cat $HOME/cmake.out | pastebinit -b p.defau.lt
make -j ${cpus} &&
make -j ${cpus} install;
