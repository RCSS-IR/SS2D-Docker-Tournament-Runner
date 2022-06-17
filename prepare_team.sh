#!/bin/bash

# ------------- PUBLIC ONES

source ./utils.sh

here=`pwd`
if [ $# -eq 0 ]; then
	echo ./prepare_team.sh name path
	exit
fi
name=$1
path=$2

rm bins/${name} -rf
mkdir bins/${name}
cp ${path}/${name}.tar.gz bins/${name}/
cd bins/${name}/
tar -xzvf ${name}.tar.gz
ls
mv ${name} bin
cd $here
./build_binary.sh
