#!/bin/bash
#redis���� gcc��gcc-c++
rpm -qa|grep gcc
if [ "$?" != "0" ];then
    echo "gcc û�а�װ,�����а�װ,��ʼ�˳�"
    exit 1
fi

rpm -qa|grep gcc-c++
if [ "$?" != "0" ];then
    echo "gcc-c++ û�а�װ,�����а�װ,��ʼ�˳�"
    exit 1
fi

script_dir="$(dirname -- "$(readlink -f -- "$0")")"
#�жϰ�װ���Ƿ�Ψһ
isAlone=$(ls $script_dir|grep -E "^redis"|grep -E "gz$"|wc -l)
if [ "$isAlone" != "1" ];then
    echo "��ű���ͬ·���´��ڶ������û�а�װ��,��ȷ�Ϻ�������Ҫ��װ�İ�װ������ʼ�˳�"
    exit 1
fi

#��ȡ��װ·��
temp=$(cat $script_dir/install_redis.conf|grep installPath)
installPath=${temp#*=}
if [ ! -e "$installPath" ];then
    echo "�����ڰ�װ·��$installPath�������д���,����ִ�нű�"
    exit 1
fi


#��ѹԴ������ű�·����redis
binPackPath=$script_dir/redis
if [ ! -e "$binPackPath" ];then
    mkdir $binPackPath
fi
packName=$(ls $script_dir|grep -E "^redis"|grep -E "gz$")
tar zxvf $script_dir/$packName -C $binPackPath --strip-components 1


#���벢ָ��·��������װ·��
cd $binPackPath
make && make install PREFIX=$installPath

#����binPachPath��redis.conf�����ļ���installPath��confĿ¼�£�������־�ļ���installPath��
mkdir $installPath/conf
touch $installPath/redis.log
cp $binPackPath/redis.conf $installPath/conf/


#����redis�����ļ�
sed -i 's/daemonize no/daemonize yes/' $installPath/conf/redis.conf
logPath=$installPath/redis.log
logPath=${logPath//\//\\/}
sed -i "s/logfile \"\"/logfile \"$logPath\"/" $installPath/conf/redis.conf

#��ȡ����
temp=$(cat $script_dir/install_redis.conf|grep password)
password=${temp#*=}
echo "requirepass $password" >> $installPath/conf/redis.conf
#��ȡredisPort
temp=$(cat $script_dir/install_redis.conf|grep redisPort)
redisPort=${temp#*=}
sed -i "s/port 6379/port $redisPort/" $installPath/conf/redis.conf

#����server
cat << EOF > /usr/lib/systemd/system/redis.service 
[Unit]
Description=Redis $redisPort
After=syslog.target network.target
[Service]
Type=forking
PrivateTmp=yes
Restart=always
ExecStart=$installPath/bin/redis-server $installPath/conf/redis.conf
ExecStop=$installPath/bin/redis-cli -h 127.0.0.1 -p $redisPort -a jcon shutdown
User=root
Group=root
LimitCORE=infinity
LimitNOFILE=100000
LimitNPROC=100000
[Install]
WantedBy=multi-user.target
EOF

#���¼���redis��������
systemctl daemon-reload
systemctl enable redis

echo "ȷ�϶˿�û�б�ռ�ú�ʹ��systemctl start redis����redis"