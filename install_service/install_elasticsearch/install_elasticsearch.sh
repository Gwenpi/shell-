#! /bin/bash

script_dir="$(dirname -- "$(readlink -f -- "$0")")"

isAlone=$(ls|grep -E "^elasticsearch"|grep -E "gz$"|wc -l)

if [ "$isAlone" != "1" ];then
    echo "��ű���ͬ·���´��ڶ������û�а�װ��,��ȷ�Ϻ�������Ҫ��װ�İ�װ������ʼ�˳�"
    exit 1
fi

function getParam()
{
    configurePath=$1
    paramName=$2
    temp=$(cat $configurePath|grep $paramName)
    if [ "$temp" = "" ];then
        echo "������${paramName}�������������ã���ʼ�˳�"
        exit 1
    fi
    param=${temp#*=}
    if [ "$param" = "" ];then
        echo "����Ϊ�գ��������ã���ʼ�˳�"
        exit 1
    fi
    eval $2=$param
}

function checkPath()
{
    path=$1
    if [ ! -d "$path" ];then
        echo "������${path}·��,��ʼ����"
        mkdir -p $path
    else
        echo "${path}·���Ѿ����ڣ�ȷ��֮�������д˽ű�����ʼ�˳�"
        exit 1
    fi
}

confPath=$script_dir/install_elasticsearch.conf

#��ȡ����
getParam $confPath installPath
getParam $confPath serverName
ls /etc/init.d/$serverName
if [ "$?" = "0" ];then
    echo "�Ѿ����ڸ÷���,���޸ķ������������д˽ű�����ʼ�˳�"
    exit 1
fi
getParam $confPath tcpTransport
getParam $confPath XmxSize
getParam $confPath XmsSize
getParam $confPath logPath
getParam $confPath dataPath
getParam $confPath httpPort

checkPath $installPath

echo "��İ�װ·��Ϊ:${installPath}"
packName=$(ls|grep -E "^elasticsearch"|grep -E "gz$")
tar zxvf $script_dir/$packName -C $installPath --strip-components 1

echo "��ʼ���û�����elasticsearch"

sed -i 's/#cluster.name/cluster.name/' ${installPath}/config/elasticsearch.yml
sed -i 's/#node.name/node.name/' ${installPath}/config/elasticsearch.yml

#��logPath��dataPath�е�'/'��Ϊ'\/'��ת�壩,�ǵ�sed�ܹ�ʶ��·��
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

echo "��ʼ����/etc/security/limits.conf"
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 131072" >> /etc/security/limits.conf
echo "* soft nproc 2048" >> /etc/security/limits.conf
echo "* hard nproc 4096" >> /etc/security/limits.conf

echo "��ʼ����/etc/sysctl.conf"
echo "vm.max_map_count=655360" >> /etc/sysctl.conf
sysctl -p


cat /etc/group|grep elasticsearch
if [ "$?" != "0" ];then
    echo "������elasticsearch�û��鿪ʼ����"
    groupadd elasticsearch
fi

cat /etc/passwd|grep elasticsearch
if [ "$?" != "0" ];then
    echo "������elasticsearch�û���ʼ����,��ָ��Ϊelasticsearch�û�"
    useradd elasticsearch -g elasticsearch
fi

echo "�ı�${installPath}�������û�"
chown -R elasticsearch:elasticsearch ${installPath}


#��������
cat << EOF > /etc/init.d/$serverName 
#!/bin/bash
#chkconfig: 345 63 37
#description: elasticsearch

#��ֹ����������ͬ��
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

echo -e "��װ�ɹ�,�ڱ�֤�˿�û�б�ռ�õ������\n��ʹ�� service ${serverName} start ��������"


