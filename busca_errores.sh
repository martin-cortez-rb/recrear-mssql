#!/bin/bash

for i in $(ls output)
do
  if [ ! -z output/$i ]
  then
    echo $i >> salida_unificada.log
    cat output/$i >> salida_unificada.log
    echo "" >> salida_unificada.log
  fi
done
