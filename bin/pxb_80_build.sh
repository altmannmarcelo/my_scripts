#!/bin/bash -x
. pxb_common.sh 8.0
# run steps necessary to prepare build
prep_build
B_TARGET=""
if [ -n "${TARGET}" ]; then
  B_TARGET=${TARGET}
fi
#CC=/usr/bin/clang CXX=/usr/bin/clang++ 
cmake ${SRC_DIR} -DBUILD_CONFIG=xtrabackup_release \
        -DCMAKE_BUILD_TYPE=${btype} \
        -DCMAKE_INSTALL_PREFIX="${INS_DIR}" \
        -DCOMPILATION_COMMENT="Percona XtraBackup, Revision ${PERCONA_REVISION}${BCOMMET}" \
        -DDOWNLOAD_BOOST=1 \
        -DWITH_PROTOBUF=bundled \
        -DWITH_BOOST="/work/boost" \
        -DWITH_MAN_PAGES=OFF \
        -DDEBUG_EXTNAME=OFF \
        -DWITH_SSL=system \
        ${CMAKE_XTRA} &&
make -j ${cpus} ${B_TARGET} &&
make -j ${cpus} install
