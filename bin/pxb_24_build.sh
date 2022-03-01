#!/bin/bash -x
. pxb_common.sh 2.4
# run steps necessary to prepare build
prep_build
cmake ${SRC_DIR} -DBUILD_CONFIG=xtrabackup_release \
        -DCMAKE_BUILD_TYPE=${btype} \
        -DCMAKE_INSTALL_PREFIX="${INS_DIR}" \
        -DCOMPILATION_COMMENT="Percona XtraBackup, Revision ${PERCONA_REVISION}${BCOMMET}" \
        -DWITH_BOOST="/work/boost" \
        -DWITH_MAN_PAGES=OFF \
        -DENCRYPT_DEBUG=ON \
        -DDEBUG_EXTNAME=OFF \
        ${CMAKE_XTRA} ;
make_install
