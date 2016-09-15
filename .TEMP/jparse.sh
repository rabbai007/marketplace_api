#!/bin/bash

json_file=$1

if [ "$#" -ne 2 ]; then
 echo "Invalid number of Arguments"
  exit 0
fi


if [ "$1" = "env.json" ]; then
  echo `cat $1 | sed -e 's/,\|]/\n/g' -e 's/"//g' | grep -i env_name | cut -d: -f 2`

elif [ "$1" = "hosts.json" ]; then
  for i in `cat $1 | sed -e 's/,\|]/\n/g' -e 's/"//g' | grep -iE "env_name|vm_name|hostname|externalip|internalip" | grep -iA3 $2`; do
    echo $i
  done
else
 
  echo "Wrong file format used. Thanks."
fi
