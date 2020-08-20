#! /bin/bash

script_dir="$(dirname -- "$(readlink -f -- "$0")")"

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
    if [ -d "$path" ];then
        echo "${path}路径已经存在，确认之后再运行此脚本，开始退出"
        exit 1
    fi
}

isAlone=$(ls ${script_dir}|grep -E "^nginx"|grep -E "gz$"|wc -l)

if [ "$isAlone" != "1" ];then
    echo "与脚本相同路径下存在多个安装包,请确认后留下需要安装的安装包，开始退出"
    exit 1
fi

#获取配置
confPath=$script_dir/install_nginx.conf
getParam $confPath installPath
checkPath $installPath
getParam $confPath serverName
ls /etc/init.d/$serverName
if [ "$?" = "0" ];then
    echo "已经存在该服务,请修改服务名后再运行此脚本，开始退出"
    exit 1
fi



#安装依赖
yum install -y pcre pcre-devel gcc zlib-devel
if [ "$?" != "0" ];then
    echo "安装依赖失败，开始退出"
    exit 1
fi


nginxPackPath=$(ls ${script_dir}|grep -E "^nginx"|grep -E "gz$")

#这里解压的是二进制源码包，还需要编译
echo "开始解压"
#解压到当前路径
tar zxvf $nginxPackPath -C ${script_dir}

if [ "$?" != "0" ];then
    echo "解压失败，开始退出"
    exit 1
fi
echo "解压完成"

#因为当前路径只有一个解压目录
dirNum=$(ls -d ${script_dir}/*/|wc -l)
if [ $dirNum != "1" ];then
    echo "脚本路径存在多个目录，找不到需要的nginx目录，请删除或者移走所有目录后，在执行脚本，开始退出"
    exit 1
fi


unpackDir=$(ls -d ${script_dir}/*/)
cd $unpackDir
#--with-http_stub_status_module --with-http_ssl_module
./configure --prefix=$installPath --with-stream && make && make install
if [ "$?" != "0" ];then
    echo "编译失败，可能是依赖错误，开始退出"
    exit 1
fi

cat << EOF > /etc/init.d/${serverName}
#!/bin/bash
# chkconfig: 345 80 20

export NGINX_HOME=${installPath}

case \$1 in
start)
    echo "Starting Nginx..."
    \$NGINX_HOME/sbin/nginx
    ;;

stop)
    echo "Stopping Nginx..."
    \$NGINX_HOME/sbin/nginx -s stop
    ;;

restart)
    echo "Restarting Nginx..."
    \$NGINX_HOME/sbin/nginx -s stop
    echo "Stopping Nginx..."
    sleep 3
    echo "Starting Nginx..."
    \$NGINX_HOME/sbin/nginx
    ;;

reload)
    echo "Reloading Nginx..."
    \$NGINX_HOME/sbin/nginx -s reload
    ;;


*)
    echo "Usage: {start|stop|restart|reload}"
    ;;
esac
exit 0

EOF

chmod 755 /etc/init.d/$serverName 
chkconfig --add $serverName
chkconfig $serverName on
echo "开机自启设置完成：请确认端口没有被占用后，使用service ${serverName} start 开启服务"



