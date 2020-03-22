#! /bin/bash

script_dir="$(dirname -- "$(readlink -f -- "$0")")"

sh $script_dir/install_mysql_5.sh

if [ "$?" != "0" ];then
    echo "安装msyql5失败"
else
    echo "安装mysql5成功"
    echo "更新/etc/profile"
    source /etc/profile
fi