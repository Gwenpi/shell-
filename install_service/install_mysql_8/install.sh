#!/bin/bash

script_dir="$(dirname -- "$(readlink -f -- "$0")")"

sh $script_dir/install_mysql_8.sh

if [ "$?" = "0" ];then
    echo "安装成功"
    source /etc/profile
else
    echo "安装错误"
fi
