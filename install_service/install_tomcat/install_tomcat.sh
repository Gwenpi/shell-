#!/bin/bash

script_dir="$(dirname -- "$(readlink -f -- "$0")")"

configurePath=$script_dir/install_tomcat.conf

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
    else
        echo "${path}路径已经存在，确认之后再运行此脚本，开始退出"
        exit 1
    fi
}


isAlone=$(ls $script_dir|grep -E "^apache-tomcat"|wc -l)

if [ "$isAlone" != "1" ];then
    echo "安装包数量不为一或不是apache-tomcat安装包,请确认后再运行此脚本,开始退出"
    exit 1
fi

getParam installPath
getParam serverName
ls /etc/init.d/$serverName
if [ "$?" = "0" ];then
    echo "已经存在该服务,请修改服务名后再运行此脚本，开始退出"
    exit 1
fi
checkPath $installPath


packName=$(ls $script_dir|grep -E "^apache-tomcat")


tar zxvf $packName -C $installPath --strip-components 1

echo "安装tomcat成功，开始配置开机自启"

cat << EOF > /etc/init.d/${serverName}
#!/bin/bash
#
# tomcat startup script for the Tomcat server
#
#
# chkconfig: 345 80 20
#

#载入环境变量,前提有安装jdk并设置环境变量
source /etc/profile

export TOMCAT_HOME=${installPath}

case \$1 in
start)
    echo "Starting Tomcat..."
    \$TOMCAT_HOME/bin/startup.sh
    ;;

stop)
    echo "Stopping Tomcat..."
    \$TOMCAT_HOME/bin/shutdown.sh
    ;;

restart)
    echo "Stopping Tomcat..."
    \$TOMCAT_HOME/bin/shutdown.sh
    sleep 5
    echo "Starting Tomcat..."
    \$TOMCAT_HOME/bin/startup.sh
    ;;

*)
    echo "Usage: {start|stop|restart}"
    ;;
esac
exit 0
EOF

chmod 755 /etc/init.d/$serverName 
chkconfig --add $serverName
chkconfig $serverName on


echo "开机自启设置完成：请确认端口没有被占用后，使用service ${serverName} start 开启服务"