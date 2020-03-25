#!/bin/bash

#目前只用于空机装jdk
#并没有考虑更新jdk的情况

script_dir="$(dirname -- "$(readlink -f -- "$0")")"


res=$(find $script_dir -name "*.gz" -o -name "*.tgz"|wc -l)

if [ "$res" != "1" ];then 
    echo "脚本所处目录下不存在jdk的gz包，或存在多个gz包，请检查后再运行此脚本，开始退出脚本"
    exit 1
fi

jdkPack=$(find $script_dir -name "*.gz" -o -name "*.tgz")
temp=$(cat $script_dir/install_jdk.conf|grep "installPath")
installPath=${temp#*=}

if [ ! -d $installPath ];then
    echo "$installPath 安装路径不存在,请自行创建，开始退出"
    exit 1
fi

echo "开始解压"
install_temp_dir="${installPath}/temp_wp_321462"
if [ ! -d $install_temp_dir ];then
    mkdir $install_temp_dir
fi


tar -zxvf $jdkPack -C $install_temp_dir
jdkName=$(ls $install_temp_dir)
mv ${install_temp_dir}/$jdkName ${installPath}/
rmdir ${install_temp_dir}

cat /etc/profile|grep JAVA_HOME
if [ "$?" != "0" ];then
    JAVA_HOME=${installPath}/$jdkName
    JRE_HOME=${JAVA_HOME}/jre
    echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile
    echo "export JRE_HOME=$JRE_HOME" >> /etc/profile
    echo 'export CLASSPATH=.:${JAVA_HOME}/lib:${JRE_HOME}/lib' >> /etc/profile
    echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/profile
    echo "环境变量配置完成"
else    
    echo "/etc/profile中已经存在JAVA_HOME环境变量,请自行修改"
fi


