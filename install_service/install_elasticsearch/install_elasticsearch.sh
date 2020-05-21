#! /bin/bash

script_dir="$(dirname -- "$(readlink -f -- "$0")")"

isAlone=$(ls|grep -E "^elasticsearch"|grep -E "gz$"|wc -l)

if [ "$isAlone" != "1" ];then
    echo "与脚本相同路径下存在多个或者没有安装包,请确认后留下需要安装的安装包，开始退出"
    exit 1
fi

function getParam()
{
    configurePath=$1
    paramName=$2
    temp=$(cat $configurePath|grep $paramName)
    if [ "$temp" = "" ];then
        echo "不存在${paramName}参数，请检查配置，开始退出"
        exit 1
    fi
    param=${temp#*=}
    if [ "$param" = "" ];then
        echo "参数为空，请检查配置，开始退出"
        exit 1
    fi
    eval $2=$param
}

function checkPath()
{
    path=$1
    if [ ! -d "$path" ];then
        echo "不存在${path}路径,开始创建"
        mkdir -p $path
    fi
}

confPath=$script_dir/install_elasticsearch.conf

#截取配置文件中的安装路径
getParam $confPath installPath

checkPath $installPath

echo "你的安装路径为:${installPath}"
packName=$(ls|grep -E "^elasticsearch"|grep -E "gz$")
tar zxvf $script_dir/$packName -C $installPath --strip-components 1

echo "开始配置基本的elasticsearch"

sed -i 's/#cluster.name/cluster.name/' ${installPath}/config/elasticsearch.yml
sed -i 's/#node.name/node.name/' ${installPath}/config/elasticsearch.yml
getParam $confPath logPath
getParam $confPath dataPath
#将logPath和dataPath中的'/'变为'\/'（转义）,是的sed能够识别路径
logPath=${logPath//\//\\/}
dataPath=${dataPath//\//\\/}
sed -i "s/#path.data: \/path\/to\/data/path.data: $dataPath/" ${installPath}/config/elasticsearch.yml
sed -i "s/#path.logs: \/path\/to\/logs/path.logs: $logPath/" ${installPath}/config/elasticsearch.yml
sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/' ${installPath}/config/elasticsearch.yml
sed -i 's/#http.port/http.port/' ${installPath}/config/elasticsearch.yml
getParam $confPath XmsSize
sed -i "s/-Xms1g/-Xms${XmsSize}g/" ${installPath}/config/jvm.options
getParam $confPath XmxSize
sed -i "s/-Xmx1g/-Xmx${XmxSize}g/" ${installPath}/config/jvm.options

echo 'http.cors.enabled: true' >> ${installPath}/config/elasticsearch.yml
echo 'http.cors.allow-origin: "*"' >> ${installPath}/config/elasticsearch.yml

echo "开始配置/etc/security/limits.conf"
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 131072" >> /etc/security/limits.conf
echo "* soft nproc 2048" >> /etc/security/limits.conf
echo "* hard nproc 4096" >> /etc/security/limits.conf

echo "开始配置/etc/sysctl.conf"
echo "vm.max_map_count=655360" >> /etc/sysctl.conf
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