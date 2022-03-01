#!/bin/bash


echo "Which dir to jump to?"
echo ""
echo "[1] PS / 5.6 / SRC"
echo "[2] PS / 5.7 / SRC"
echo "[3] PS / 8.0 / SRC"

read option

if [ "$option" == "1" ]; then
  cd /work/ps/src/5.6/
  exit;
fi