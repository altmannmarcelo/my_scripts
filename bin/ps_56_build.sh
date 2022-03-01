#!/bin/bash
. ps_common.sh 5.6
# run steps necessary to prepare build
prep_build
cmake ${SRC_DIR} -DBUILD_CONFIG=mysql_release \
        -DCMAKE_BUILD_TYPE=${btype} \
        -DFEATURE_SET=community \
        -DCMAKE_INSTALL_PREFIX="${INS_DIR}" \
        -DMYSQL_DATADIR="${INS_DIR}/data" \
        -DWITH_PAM=ON \
        -DWITHOUT_TOKUDB=OFF  \
        -DWITH_SCALABILITY_METRICS=ON \
        -DWITH_INNODB_MEMCACHED=ON \
        -DWITH_EDITLINE=bundled \
        -DWITH_ZLIB=system \
        -DWITH_LIBEVENT=bundled \
        -DCOMPILATION_COMMENT="Percona Server (GPL), Revision ${PERCONA_REVISION}${BCOMMET}" \
        -DWITH_NUMA=ON \
        -DMYSQL_SERVER_SUFFIX="" \
        -DDEBUG_EXTNAME=OFF \
        -DHAVE_TIME=ON \
        -DHAVE_SYS_TIMEB_H=OFF \
        -DWITH_UNIT_TESTS=0;
make -j ${cpus} &&
make -j ${cpus} install;