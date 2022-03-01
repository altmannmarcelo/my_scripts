#!/bin/bash 
SRC_DIR=/work/mysql/src
INS_DIR=/work/mysql/ins
CMAKE_XTRA=""
cmake ${SRC_DIR} \
        -DCMAKE_BUILD_TYPE=Debug \
        -DCMAKE_INSTALL_PREFIX="${INS_DIR}" \
        -DDOWNLOAD_BOOST=1 \
        -DWITH_BOOST="/work/boost" \
        -DDEBUG_EXTNAME=OFF \
        ${CMAKE_XTRA} &&
make -j ${cpus} &&
make -j ${cpus} install