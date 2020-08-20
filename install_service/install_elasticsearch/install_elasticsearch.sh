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
    else
        echo "${path}路径已经存在，确认之后再运行此脚本，开始退出"
        exit 1
    fi
}

confPath=$script_dir/install_elasticsearch.conf

#获取配置
getParam $confPath installPath
getParam $confPath serverName
ls /etc/init.d/$serverName
if [ "$?" = "0" ];then
    echo "已经存在该服务,请修改服务名后再运行此脚本，开始退出"
    exit 1
fi
getParam $confPath tcpTransport
getParam $confPath XmxSize
getParam $confPath XmsSize
getParam $confPath logPath
getParam $confPath dataPath
getParam $confPath httpPort

checkPath $installPath

echo "你的安装路径为:${installPath}"
packName=$(ls|grep -E "^elasticsearch"|grep -E "gz$")
tar zxvf $script_dir/$packName -C $installPath --strip-components 1

echo "开始配置基本的elasticsearch"

sed -i 's/#cluster.name/cluster.name/' ${installPath}/config/elasticsearch.yml
sed -i 's/#node.name/node.name/' ${installPath}/config/elasticsearch.yml

#将logPath和dataPath中的'/'变为'\/'（转义）,是的sed能够识别路径
logPath=${logPath//\//\\/}
dataPath=${dataPath//\//\\/}
sed -i "s/#path.data: \/path\/to\/data/path.data: $dataPath/" ${installPath}/config/elasticsearch.yml
sed -i "s/#path.logs: \/path\/to\/logs/path.logs: $logPath/" ${installPath}/config/elasticsearch.yml
sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/' ${installPath}/config/elasticsearch.yml
sed -i "s/#http.port: 9200/http.port: $httpPort/" ${installPath}/config/elasticsearch.yml
sed -i "s/-Xms1g/-Xms${XmsSize}g/" ${installPath}/config/jvm.options
sed -i "s/-Xmx1g/-Xmx${XmxSize}g/" ${installPath}/config/jvm.options


echo "transport.tcp.port: $tcpTransport" >> ${installPath}/config/elasticsearch.yml
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


#配置自启
cat << EOF > /etc/init.d/$serverName 
#!/bin/bash
#chkconfig: 345 63 37
#description: elasticsearch

#防止环境变量不同步
source /etc/profile

export ES_HOME=${installPath}

case \$1 in
        start)
                su elasticsearch<<!
                cd \$ES_HOME
                ./bin/elasticsearch -d -p pid
                exit
!
                echo "elasticsearch is started"
                ;;
        stop)
                pid=\$(cat \$ES_HOME/pid)
                kill -9 \$pid
                echo "elasticsearch is stopped"
                ;;
        restart)
                pid=\$(cat \$ES_HOME/pid)
                kill -9 \$pid
                echo "elasticsearch is stopped"
                sleep 1
                su elasticsearch<<!
                cd \$ES_HOME
                ./bin/elasticsearch -d -p pid
                exit
!
                echo "elasticsearch is started"
        ;;
    *)
        echo "start|stop|restart"
        ;;
esac
exit 0
EOF

chmod 755 /etc/init.d/$serverName 
chkconfig --add $serverName
chkconfig $serverName on

echo -e "安装成功,在保证端口没有被占用的情况下\n请使用 service ${serverName} start 开启服务。"


