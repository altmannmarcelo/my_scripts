#!/bin/bash
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo "##### START OF TEST ######"
for site in https://blog.marceloaltmann.com https://pt.blog.marceloaltmann.com
do
  echo "Checking http status for $site"
  curl -Iv $site || exit 1;
  HTTP_RETURN_CODE=$(curl -Is $site | grep HTTP | awk '{print $2}')
  if [ $HTTP_RETURN_CODE -ne "200" ];
  then
    echo "[ERROR] HTTP return code for ${site} is ${HTTP_RETURN_CODE}. It should be 200"
    exit 1;
  fi
  if [ ${site} == "https://blog.marceloaltmann.com" ];
  then
    CHECK_TEXT='Whatever action you do on the parent table, child column will reset to NULL'
  else
    CHECK_TEXT='Qualquer alteração na tabela pai, vai resetar a coluna na tabela filho para NULL'
  fi
  CHECK_TEXT_COUNT=$(curl -s ${site}/en-mysql-how-to-add-a-foreign-key-on-new-or-existing-table-pt-como-adicionar-chave-estrangeira-em-tabela-nova-ou-existente/ | grep "${CHECK_TEXT}" | wc -l)
  if [ $CHECK_TEXT_COUNT -ne "1" ];
  then
    echo "[ERROR] could not find phrase on ${site}/mysql-how-to-add-a-foreign-key/"
    exit 1;
  fi
done