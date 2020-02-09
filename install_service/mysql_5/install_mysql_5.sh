#!/bin/bash

#安装前的环境检测
#检测端口
read -p "请输入mysql端口:" port
read -p "你输入的端口号为:${port}(确认y/重新输入 其他):" input
while [ "$input" != "y" ]
do
    read -p "请输入mysql端口:" port
    read -p "你输入的端口号为:${port}(确认y/重新输入 其他):" input
done

rpm -qa|grep net-tools
if [ "$?" != "0" ];then
    echo "安装net-tools"
    yum install -y net-tools
fi

netstat -anp|grep -w $port
if [ "$?" = "0" ];then
    read -p "$port端口被占用是否继续(继续y/退出 其他)：" input
    if [ "$input" != "y" ];then
        echo "开始退出"
        exit
    fi
fi

#检测mysql
echo "===开始检测当前环境==="
rpm -qa|grep mysql  
if [ "$?" = "0" ];then
    echo "已经安装mysql,请卸载，并删除之前的配置文件，开始退出"
    exit
fi
#检测mysql用户和用户组
cat /etc/group | grep mysql 
if [ "$?" != "0" ];then
    groupadd mysql
fi
cat /etc/passwd |grep mysql 
if [ "$?" != "0" ];then
    useradd -g mysql -s /sbin/nologin mysql
fi
groups mysql |grep "mysql : mysql"
if [ "$?" != "0" ];then
    echo "不存在mysql:mysql,请手动添加，开始退出"
    exit
fi


rpm -qa|grep mariadb 
if [ "$?" = "0" ];then
    yum remove -y mariadb* 
fi

echo "开始安装libaio依赖"
yum install libaio -y 
if [ "$?" != "0" ];then
    echo "安装失败，开始退出"
    exit
else
    echo "安装libaio包成功"
fi

echo "===检测完毕==="

script_abs=$(readlink -f "$0")
script_dir=$(dirname $script_abs)

mysqlPack=$(ls $script_dir|grep mysql-5*gz)

if [ -z "$mysqlPack" ];then
    echo "脚本的同级目录下没有mysql5版本的.gz结尾的安装包，请放入安装包，开始退出"
    exit
fi

#因为解压完后会生成一个mysql*的文件夹。所以这里创建一个mysql还有一个临时文件夹
#将解压后的文件夹放入临时文件夹，此时零时文件夹里只有解压后的文件夹，用ls就可以提取文件夹名
#将解压后的文件夹下的所有文件cp到mysql下，最后删除临时文件夹
mysqlDir="/usr/local/mysql"
mysqlTempDir="/usr/local/mysql_temp_wp"
echo "开始解压"
if [ ! -d $mysqlTempDir ];then
    mkdir $mysqlTempDir
else
    echo "已存在/usr/local/mysql_temp_wp目录,请确认无用后删除,开始退出"
    exit
fi

if [ ! -d $mysqlDir ];then
    mkdir $mysqlDir
else
    echo "已存在/usr/local/mysql目录,请确认无用后删除,开始退出"
    exit
fi

tar zxvf $mysqlPack -C $mysqlTempDir 
if [ "$?" != "0" ];then
    echo "解压失败开始退出"
else
    echo "解压成功"
fi
mysqlUnzipPackName=$(ls $mysqlTempDir)
mv ${mysqlTempDir}/${mysqlUnzipPackName}/* $mysqlDir

#这里用rmdir更安全点
echo "删除临时文件夹${mysqlTempDir}"
rmdir ${mysqlTempDir}/${mysqlUnzipPackName}
rmdir ${mysqlTempDir}


echo "创建log,run,etc,data,binlogs路径，并配置软连接"
mkdir -p /usr/local/mysql/{log,etc,run}
mkdir -p /data/mysql/{data,binlogs}
ln -s /data/mysql/data  /usr/local/mysql/data
ln -s /data/mysql/binlogs   /usr/local/mysql/binlogs
chown -R mysql.mysql /usr/local/mysql/{data,binlogs,log,etc,run}
chown -R mysql.mysql /data/mysql

#配置PATH可以让系统在使用mysql命令的时候，自动到PATH的路径下查找有没有相关命令
echo "配置PATH"
echo "export PATH=$PATH:/usr/local/mysql/bin" >> /etc/profile
source /etc/profile

echo "删除/etc/my.cnf"
rm -f /etc/my.cnf

echo "创建新的my.cnf"
cat <<EOF > /usr/local/mysql/etc/my.cnf
[client]
port = $port
socket = /usr/local/mysql/run/mysql.sock
[mysqld]
port = $port
socket = /usr/local/mysql/run/mysql.sock
pid_file = /usr/local/mysql/run/mysql.pid
datadir = /usr/local/mysql/data
default_storage_engine = InnoDB
log-error = /usr/local/mysql/log/mysql_error.log
log-bin = /usr/local/mysql/binlogs/mysql-bin
slow_query_log = 1
slow_query_log_file = /usr/local/mysql/log/mysql_slow_query.log
long_query_time = 5
server-id=1
EOF


echo "初始化mysql&ssl_ras"
mysqld --initialize --user=mysql --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data
mysql_ssl_rsa_setup --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data/

echo "创建mysqld.service"
cat <<EOF > /usr/lib/systemd/system/mysqld.service
# Copyright (c) 2015, 2016, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
#
# systemd service file for MySQL forking server
#

[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network.target
After=syslog.target

[Install]
WantedBy=multi-user.target

[Service]
User=mysql
Group=mysql

Type=forking

PIDFile=/usr/local/mysql/run/mysqld.pid

# Disable service start and stop timeout logic of systemd for mysqld service.
TimeoutSec=0

# Execute pre and post scripts as root
PermissionsStartOnly=true

# Needed to create system tables
#ExecStartPre=/usr/bin/mysqld_pre_systemd

# Start main service
ExecStart=/usr/local/mysql/bin/mysqld --daemonize --pid-file=/usr/local/mysql/run/mysqld.pid $MYSQLD_OPTS

# Use this to switch malloc implementation
EnvironmentFile=-/etc/sysconfig/mysql

# Sets open_files_limit
LimitNOFILE = 65535

Restart=on-failure

RestartPreventExitStatus=1

PrivateTmp=false
EOF
echo "设置开启重启"
systemctl daemon-reload
systemctl enable mysqld.service
systemctl is-enabled mysqld
echo "启动mysqld服务"
systemctl start mysqld


read -p "请问需要设置root密码吗?(y/其他)" input
if [ "$input" != "y" ];then
    echo "没有修改root密码,完成安装,初始密码在/usr/local/mysql/log/mysql_error.log,开始退出"
    exit
fi
read -p "请输入密码,用于设置root用户的密码:" password
read -p "你输入的密码是${password},(继续y/重新输入 其他):" input
while [[ "$input" != "y" ]]
do
    read -p "请输入密码,用于设置root用户的密码:" password
    read -p "你输入的密码是${password},(继续y/重新输入 其他):" input
done


echo "开始修改root用户密码"
string=$(grep 'temporary password' /usr/local/mysql/log/mysql_error.log)
mysqlInitPass=$(echo ${string##* })
mysql --connect-expired-password -uroot -p${mysqlInitPass} -e "alter user 'root'@'localhost' identified by '${password}';"
if [ "$?" != "0" ];then
    echo "设置失败,请手动设置,初始密码在/usr/local/mysql/log/mysql_error.log,开始退出"
    exit
else
    echo "设置成功"
fi
    


read -p "请问需要创建远程连接账户吗？(y/其他):" input
if [ "$input" != "y" ];then
    echo "没有创建远程连接账户，开始退出"
    exit
fi

read -p "请输入远程连接账户的账户名:" userRCU
read -p "你的用户名为:${userRCU},(继续y/重新输入 其他)" input
while [ "$input" != "y" ]
do
    read -p "请输入远程连接账户的账户名:" userRCU
    read -p "你的用户名为:${userRCU},(继续y/重新输入 其他)" input
done

read -s -p "请输入密码:" pass1RCU
read -s -p "请确认密码:" pass2RCU

while [ "$pass1RCU" != "$pass2RCU" ]
do
    echo "两次密码不一致，请重新输入"
    read -s -p "请输入密码:" pass1RCU
    read -s -p "请确认密码:" pass2RCU
done

echo "开始创建远程连接用户"
mysql --connect-expired-password -uroot -p${password} -e "GRANT ALL PRIVILEGES ON *.* TO '${userRCU}'@'%' IDENTIFIED BY '${pass1RCU}' WITH GRANT OPTION;"
if [ "$?" != "0" ];then
    echo "创建远程连接用户失败，开始退出"
    exit
fi
echo "创建完成，请自行开放防火墙端口"

echo "done"


