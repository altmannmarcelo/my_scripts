#!/bin/bash -x
. ps_common.sh 8.0

cd ${INS_DIR};

FILE="bin/mysqld.my"
if [[ ! -f "${FILE}" ]]; then
  cat <<EOF > "${FILE}"
{
"read_local_manifest": true
}
EOF
fi

FILE="./lib/plugin/component_keyring_file.cnf"
if [[ ! -f "${FILE}" ]]; then
  cat <<EOF > "${FILE}"
{
"read_local_config": true
}
EOF
fi

FILE="./datadir1/mysqld.my"
if [[ ! -f "${FILE}" ]]; then
cat <<EOF > "${FILE}"
{
  "components": "file://component_keyring_file"
}
EOF

fi

FILE="./datadir1/component_keyring_file.cnf"
if [[ ! -f "${FILE}" ]]; then

cat <<EOF > "${FILE}"
{
"path": "${INS_DIR}/keyring_comp",
"read_only": false
}
EOF
fi

stop
start ${INS_DIR}/my.cnf