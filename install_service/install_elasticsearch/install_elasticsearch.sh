#! /bin/bash

script_dir="$(dirname -- "$(readlink -f -- "$0")")"

isAlone=$(ls|grep -E "^elasticsearch"|grep -E "gz$"|wc -l)

if [ "$isAlone" != "1" ];then
    echo "与脚本相同路径下存在多个或者没有安装包,请确认后留下需要安装的安装包，开始退出"
    exit 1
fi

#截取配置文件中的安装路径
temp=$(cat $script_dir/install_elasticsearch.conf|grep "installPath")
installPath=${temp#*=}

if [ ! -d $installPath ];then
    echo "$installPath 安装路径不存在,请自行创建，开始退出"
    exit 1
fi

echo "你的安装路径为:${installPath}"
packName=$(ls|grep -E "^elasticsearch"|grep -E "gz$")
tar zxvf $script_dir/$packName -C $installPath --strip-components 1

echo "开始配置基本的elasticsearch"

sed -i 's/#cluster.name/cluster.name/' ${installPath}/config/elasticsearch.yml
sed -i 's/#node.name/node.name/' ${installPath}/config/elasticsearch.yml
temp=$(cat $script_dir/install_elasticsearch.conf|grep "logPath")
logPath=${temp#*=}
temp=$(cat $script_dir/install_elasticsearch.conf|grep "dataPath")
dataPath=${temp#*=}
#将logPath和dataPath中的'/'变为'\/'（转义）,是的sed能够识别路径
logPath=${logPath//\//\\/}
dataPath=${dataPath//\//\\/}
sed -i "s/#path.data: \/path\/to\/data/path.data: $dataPath/" ${installPath}/config/elasticsearch.yml
sed -i "s/#path.logs: \/path\/to\/logs/path.logs: $logPath/" ${installPath}/config/elasticsearch.yml
sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/' ${installPath}/config/elasticsearch.yml
sed -i 's/#http.port/http.port/' ${installPath}/config/elasticsearch.yml

echo "开始配置/etc/security/limits.conf"
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 131072" >> /etc/security/limits.conf
echo "* soft nproc 2048" >> /etc/security/limits.conf
echo "* hard nproc 4096" >> /etc/security/limits.conf

echo "开始配置/etc/sysctl.conf"
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
sysctl -p


cat /etc/group|grep elasticsearch
if [ "$?" != "0" ];then
    echo "不存在elasticsearch用户组开始创建"
    groupadd elasticsearch
fi

cat /etc/passwd|grep elasticsearch
if [ "$?" != "0" ];then
    echo "不存在elasticsearch用户开始创建,并指定为elasticsearch用户"
    useradd elasticsearch -g elasticsearch
fi

echo "改变${installPath}的所属用户"
chown -R elasticsearch:elasticsearch ${installPath}

