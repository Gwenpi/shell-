#! /bin/bash

script_dir="$(dirname -- "$(readlink -f -- "$0")")"

sh $script_dir/install_java.sh

if [ "$?" != "0" ];then
    echo "安装openJDK失败"
else
    echo "安装openJDK成功"
    echo "更新/etc/profile"
    source /etc/profile
fi