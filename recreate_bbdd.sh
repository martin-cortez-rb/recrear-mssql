#!/bin/bash

#set -x

[ $# -lt 2 ] && { echo "Uso: $0 <nombre_base> <puerto>"; exit 1; }

BASE=$1
PORT=$2
#LISTA=$(find $BASE -type f -name "*.sql")
LISTA_TABLES=$(find $BASE -type f -name "*.sql" | grep Tables)
LISTA_OTROS=$(find $BASE -type f -name "*.sql"| grep -v Tables)

echo "TABLAS"
echo $LISTA_TABLES
echo "OTROS"
echo $LISTA_OTROS

# Primero damos de alta las tablas
for TABLA in $(echo $LISTA_TABLES)
do
  ARCH=$(echo $TABLA|awk -F\/ '{print $3}')
  if [ ! -f output/$BASE"_"$ARCH.log ]
  then
    touch output/$BASE"_"$ARCH.log
  fi
  sqlcmd -S tcp:localhost,$PORT -d $BASE -U sa -P Password01 -i $TABLA -o output/$BASE"_"$ARCH.log
  echo "$TABLA Aplicado."
done

# Luego stored procedures, triggers, views, etc
for OTRO in $(echo $LISTA_OTROS)
do
  DIR=$(echo $OTRO|awk -F\/ '{print $1"/"$2}')
  ARCH=$(echo $OTRO|awk -F\/ '{print $3}')
  NOM=$(basename $ARCH .sql)
  ARCH_UTF8=$(echo $DIR"/"$NOM"_utf8.sql")
  if [ ! -f output/$BASE"_"$ARCH.log ]
  then
    touch output/$BASE"_"$ARCH.log
  fi
  # Convertimos a UTF-8 los archivos sql de microsoft
  iconv -f UTF-16LE -t UTF-8 $OTRO -o $ARCH_UTF8
  # Agregamos un un "GO" a cada fin de sentencia para que no de error su ejecucion
  sed -i -e '/^ENABLE/iGO' -e '/^create/iGO' -e '/^CREATE/iGO' -e '/^enable/iGO' $ARCH_UTF8
  sqlcmd -S tcp:localhost,$PORT -d $BASE -U sa -P Password01 -i $ARCH_UTF8 -o output/$BASE"_"$ARCH.log
  echo "$ARCH_UTF8 Aplicado."
done
