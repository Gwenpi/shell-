#!/bin/bash


script_dir="$(dirname -- "$(readlink -f -- "$0")")"

configurePath=$script_dir/install_mysql_58.conf

function getParam()
{
    paramName=$1
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
    eval $1=$param
}

function checkPath()
{
    path=$1
    if [ ! -d "$path" ];then
        echo "不存在${path}路径,开始创建"
        mkdir -p $path
    fi
}

function exeFailToExitAndOutMessage()
{
    if [ "$?" != "0" ];then
        message=$1
        echo "$message"
        exit 1
    fi
}

#安装依赖
if [[ ! $(rpm -qa|grep libaio) ]] || [[ ! $(rpm -qa|grep libaio-devel) ]];then
    echo "缺少libaio依赖，开始安装"
    yum install libaio* -y
    exeFailToExitAndOutMessage "安装libaio依赖失败，开始退出"
fi

if [[ ! $(rpm -qa|grep numactl) ]];then
    echo "缺少libnuma.so.1依赖开始安装numactl"
    yum install numactl -y
    exeFailToExitAndOutMessage "安装numactl依赖失败，开始退出"
fi

getParam installPath
getParam logPath
getParam dataPath
getParam port
getParam serverName


isAlone=$(ls $script_dir|grep -E "^mysql-"|wc -l)

if [ "$isAlone" != "1" ];then
    echo "安装包数量不为一或不是mysql安装包,请确认后再运行此脚本,开始退出"
    exit 1
fi


packName=$(ls $script_dir|grep -E "^mysql-")

checkPath $installPath
checkPath $logPath
checkPath $dataPath

if [[ $(file ${packName}|grep XZ) ]];then
    tar Jxvf $script_dir/$packName -C $installPath --strip-components 1
elif [[ $(file ${packName}|grep gzip) ]];then
    tar zxvf $script_dir/$packName -C $installPath --strip-components 1
else
    echo "安装包文件格式不支持,开始退出"
    exit 1
fi

if [[ ! $(cat /etc/group |grep mysql) ]];then
    echo "不存在mysql组，开始创建"
    groupadd mysql
fi

if [[ ! $(cat /etc/passwd |grep mysql) ]];then
    echo "不存在mysql用户，开始创建，并指定为mysql组"
    useradd -g mysql mysql
fi


date=$(date +%Y%m%d)

if [ -e /etc/my.cnf ];then
    mv /etc/my.cnf /etc/my.cnf_bak_${date}
fi

touch $installPath/my.cnf

binlogExpire=""
#提取"mysql-"后面的主版本号
majorVersion=${packName:6:1}
if [ "$majorVersion" = "5" ];then
    binlogExpire="expire_logs_days=7"
elif [ "$majorVersion" = "8" ];then
    binlogExpire="binlog_expire_logs_seconds=604800"
else
    echo "主版本为：$majorVersion,不支持该版本"
    exit 1
fi

cat << EOF > $installPath/my.cnf
[client]
port=${port}
socket=${dataPath}/mysql.sock
default-character-set=utf8

[mysqld]
basedir=$installPath
datadir=$dataPath
port=${port}
socket=${dataPath}/mysql.sock
pid-file=${dataPath}/mysql.pid


character-set-server=utf8
log_error=${logPath}/mysql.err
$binlogExpire

server-id=1
log_bin=${logPath}/binlog
log_bin_trust_function_creators=1

general_log_file=${logPath}/general_log
general_log=1

slow_query_log=ON
long_query_time=2
slow_query_log_file=${logPath}/query_log
log_queries_not_using_indexes=ON

max_heap_table_size=48
wait_timeout=2880000
interactive_timeout = 2880000

sql_mode='STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'

max_connections=500

lower_case_table_names=1 


skip-grant-tables
EOF

chown -R mysql:mysql $installPath

echo "export MYSQL_HOME=$installPath" >> /etc/profile
echo 'export PATH=$MYSQL_HOME/bin:$PATH' >> /etc/profile
source /etc/profile

mysqld --initialize --user=mysql --datadir=$dataPath --basedir=$installPath

exeFailToExitAndOutMessage "mysqld 初始化失败，开始退出"


echo "开始设置init.d"

sedInstallPath=$installPath
sedInstallPath=${sedInstallPath//\//\\/}
sedDataPath=$dataPath
sedDataPath=${sedDataPath//\//\\/}

sed -i ":label;N;s/datadir=\n/datadir=$sedDataPath\n/;b label" $installPath/support-files/mysql.server
sed -i ":label;N;s/basedir=\n/basedir=$sedInstallPath\n/;b label" $installPath/support-files/mysql.server

cp $installPath/support-files/mysql.server /etc/init.d/$serverName
chmod +644 /etc/init.d/$serverName 
chkconfig --add $serverName
chkconfig --list

#ln -s ${installPath}/bin/mysql /usr/bin

#启动mysql服务
service $serverName start
exeFailToExitAndOutMessage "启动myql失败，开始退出"

#询问是否添加locahost和远程用户
isChangeLocalPassword='false'
read -p "是否改变本地用户密码？ 是：y/否：任意:" input
if [ "$input" = "y" ];then
    read -p "请输入新的密码：" password
    read -p "你输入的密码是${password}. 确认：y/重新：任意：" input
    while [ "$input" != "y" ]
    do
        read -p "请输入新的密码：" password
        read -p "你输入的密码是${password}. 确认：y/重新：任意：" input
    done
    mysql -e "flush privileges;use mysql;alter user 'root'@'localhost' identified with mysql_native_password by '${password}';flush privileges;"
    if [ "$?" != "0" ];then
        echo "密码设置失败请到${logPath}/mysql.err中查找初始化密码"
    else
        isChangeLocalPassword='true'
        localPassword=$password
    fi
fi

read -p "是否添加远程账号? 是：y/否：任意" input
if [ "$input" = "y" ];then
    read -p "请输入远程账号的用户名：" userName
    read -p "你输入的用户名为：${userName} 确认：y/重新：任意：" input
    while [ "$input" != "y" ]
    do
        read -p "请输入远程账号的用户名：" userName
        read -p "你输入的用户名为：${userName} 确认：y/重新：任意：" input
    done
    
    read -p "请输入远程账号的密码：" password
    read -p "你输入的密码为：${password} 确认：y/重新：任意：" input
    while [ "$input" != "y" ]
    do
        read -p "请输入远程账号的密码：" password
        read -p "你输入的密码为：${password} 确认：y/重新：任意：" input
    done

    #skip-grant-tables参数不知道为什么不能连续更改密码，只能使用前一个用户登录之后进行更改密码
    if [ $isChangeLocalPassword = "true" ];then
        mysql -uroot -p${localPassword} -e "flush privileges;use mysql;create user '${userName}'@'%' identified with mysql_native_password by '${password}';grant all privileges on *.* to '${userName}'@'%' with grant option;flush privileges;"
    else
        mysql -e "flush privileges;use mysql;create user '${userName}'@'%' identified with mysql_native_password by '${password}';grant all privileges on *.* to '${userName}'@'%' with grant option;flush privileges;"
    fi

    if [ "$?" != "0" ];then
        echo "添加远程用户失败"
    fi  

fi

#将免密登录注释后，重启mysql

sed -i "s/skip-grant-tables/#skip-grant-tables/" ${installPath}/my.cnf

service $serverName restart
exeFailToExitAndOutMessage "重启失败，开始退出"

echo "安装完成,请自行打开mysql的${port}端口"
exit 0