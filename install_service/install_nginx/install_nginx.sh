#! /bin/bash

script_dir="$(dirname -- "$(readlink -f -- "$0")")"

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
    if [ -d "$path" ];then
        echo "${path}·���Ѿ����ڣ�ȷ��֮�������д˽ű�����ʼ�˳�"
        exit 1
    fi
}

isAlone=$(ls ${script_dir}|grep -E "^nginx"|grep -E "gz$"|wc -l)

if [ "$isAlone" != "1" ];then
    echo "��ű���ͬ·���´��ڶ����װ��,��ȷ�Ϻ�������Ҫ��װ�İ�װ������ʼ�˳�"
    exit 1
fi

#��ȡ����
confPath=$script_dir/install_nginx.conf
getParam $confPath installPath
checkPath $installPath
getParam $confPath serverName
ls /etc/init.d/$serverName
if [ "$?" = "0" ];then
    echo "�Ѿ����ڸ÷���,���޸ķ������������д˽ű�����ʼ�˳�"
    exit 1
fi



#��װ����
yum install -y pcre pcre-devel gcc zlib-devel
if [ "$?" != "0" ];then
    echo "��װ����ʧ�ܣ���ʼ�˳�"
    exit 1
fi


nginxPackPath=$(ls ${script_dir}|grep -E "^nginx"|grep -E "gz$")

#�����ѹ���Ƕ�����Դ���������Ҫ����
echo "��ʼ��ѹ"
#��ѹ����ǰ·��
tar zxvf $nginxPackPath -C ${script_dir}

if [ "$?" != "0" ];then
    echo "��ѹʧ�ܣ���ʼ�˳�"
    exit 1
fi
echo "��ѹ���"

#��Ϊ��ǰ·��ֻ��һ����ѹĿ¼
dirNum=$(ls -d ${script_dir}/*/|wc -l)
if [ $dirNum != "1" ];then
    echo "�ű�·�����ڶ��Ŀ¼���Ҳ�����Ҫ��nginxĿ¼����ɾ��������������Ŀ¼����ִ�нű�����ʼ�˳�"
    exit 1
fi


unpackDir=$(ls -d ${script_dir}/*/)
cd $unpackDir
#--with-http_stub_status_module --with-http_ssl_module
./configure --prefix=$installPath --with-stream && make && make install
if [ "$?" != "0" ];then
    echo "����ʧ�ܣ��������������󣬿�ʼ�˳�"
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
echo "��������������ɣ���ȷ�϶˿�û�б�ռ�ú�ʹ��service ${serverName} start ��������"



