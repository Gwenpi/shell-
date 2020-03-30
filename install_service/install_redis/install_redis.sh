#!/bin/bash
#redis依赖 gcc和gcc-c++
rpm -qa|grep gcc
if [ "$?" != "0" ];then
    echo "gcc 没有安装,请自行安装,开始退出"
    exit 1
fi

rpm -qa|grep gcc-c++
if [ "$?" != "0" ];then
    echo "gcc-c++ 没有安装,请自行安装,开始退出"
    exit 1
fi

script_dir="$(dirname -- "$(readlink -f -- "$0")")"
#判断安装包是否唯一
isAlone=$(ls $script_dir|grep -E "^redis"|grep -E "gz$"|wc -l)
if [ "$isAlone" != "1" ];then
    echo "与脚本相同路径下存在多个或者没有安装包,请确认后留下需要安装的安装包，开始退出"
    exit 1
fi

#获取安装路径
temp=$(cat $script_dir/install_redis.conf|grep installPath)
installPath=${temp#*=}
if [ ! -e "$installPath" ];then
    echo "不存在安装路径$installPath，请自行创建,后再执行脚本"
    exit 1
fi


#解压源码包到脚本路径的redis
binPackPath=$script_dir/redis
if [ ! -e "$binPackPath" ];then
    mkdir $binPackPath
fi
packName=$(ls $script_dir|grep -E "^redis"|grep -E "gz$")
tar zxvf $script_dir/$packName -C $binPackPath --strip-components 1


#编译并指定路径，即安装路径
cd $binPackPath
make && make install PREFIX=$installPath

#复制binPachPath的redis.conf配置文件到installPath的conf目录下，创建日志文件到installPath下
mkdir $installPath/conf
touch $installPath/redis.log
cp $binPackPath/redis.conf $installPath/conf/


#配置redis配置文件
sed -i 's/daemonize no/daemonize yes/' $installPath/conf/redis.conf
logPath=$installPath/redis.log
logPath=${logPath//\//\\/}
sed -i "s/logfile \"\"/logfile \"$logPath\"/" $installPath/conf/redis.conf

#获取密码
temp=$(cat $script_dir/install_redis.conf|grep password)
password=${temp#*=}
echo "requirepass $password" >> $installPath/conf/redis.conf
#获取redisPort
temp=$(cat $script_dir/install_redis.conf|grep redisPort)
redisPort=${temp#*=}
sed -i "s/port 6379/port $redisPort/" $installPath/conf/redis.conf

#创建server
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

#重新加载redis服务配置
systemctl daemon-reload
systemctl enable redis

echo "确认端口没有被占用后，使用systemctl start redis启动redis"