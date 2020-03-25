#! /bin/bash

script_dir="$(dirname -- "$(readlink -f -- "$0")")"

isAlone=$(ls|grep -E "^elasticsearch"|grep -E "gz$"|wc -l)

if [ "$isAlone" != "1" ];then
    echo "��ű���ͬ·���´��ڶ������û�а�װ��,��ȷ�Ϻ�������Ҫ��װ�İ�װ������ʼ�˳�"
    exit 1
fi

#��ȡ�����ļ��еİ�װ·��
temp=$(cat $script_dir/install_elasticsearch.conf|grep "installPath")
installPath=${temp#*=}

if [ ! -d $installPath ];then
    echo "$installPath ��װ·��������,�����д�������ʼ�˳�"
    exit 1
fi

echo "��İ�װ·��Ϊ:${installPath}"
packName=$(ls|grep -E "^elasticsearch"|grep -E "gz$")
tar zxvf $script_dir/$packName -C $installPath --strip-components 1

echo "��ʼ���û�����elasticsearch"

sed -i 's/#cluster.name/cluster.name/' ${installPath}/config/elasticsearch.yml
sed -i 's/#node.name/node.name/' ${installPath}/config/elasticsearch.yml
temp=$(cat $script_dir/install_elasticsearch.conf|grep "logPath")
logPath=${temp#*=}
temp=$(cat $script_dir/install_elasticsearch.conf|grep "dataPath")
dataPath=${temp#*=}
#��logPath��dataPath�е�'/'��Ϊ'\/'��ת�壩,�ǵ�sed�ܹ�ʶ��·��
logPath=${logPath//\//\\/}
dataPath=${dataPath//\//\\/}
sed -i "s/#path.data: \/path\/to\/data/path.data: $dataPath/" ${installPath}/config/elasticsearch.yml
sed -i "s/#path.logs: \/path\/to\/logs/path.logs: $logPath/" ${installPath}/config/elasticsearch.yml
sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/' ${installPath}/config/elasticsearch.yml
sed -i 's/#http.port/http.port/' ${installPath}/config/elasticsearch.yml

echo "��ʼ����/etc/security/limits.conf"
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 131072" >> /etc/security/limits.conf
echo "* soft nproc 2048" >> /etc/security/limits.conf
echo "* hard nproc 4096" >> /etc/security/limits.conf

echo "��ʼ����/etc/sysctl.conf"
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
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

