#! /bin/bash

script_dir="$(dirname -- "$(readlink -f -- "$0")")"

isAlone=$(ls ${script_dir}|grep -E "^nginx"|grep -E "gz$"|wc -l)

if [ "$isAlone" != "1" ];then
    echo "与脚本相同路径下存在多个安装包,请确认后留下需要安装的安装包，开始退出"
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

#安装依赖，这个以后要改成离线安装
yum install -y pcre pcre-devel gcc zlib-devel

temp=$(cat $script_dir/install_nginx.conf|grep installPath)
installPath=${temp#*=}

unpackDir=$(ls -d ${script_dir}/*/)
cd $unpackDir
./configure --prefix=$installPath && make && make install
if [ "$?" != "0" ];then
    echo "编译失败，可能是依赖错误，开始退出"
    exit 1
fi

ls /usr/lib/systemd/system/nginx.service

if [ "$?" != "0" ];then
    echo "开始设置systemctl 服务"
    touch /usr/lib/systemd/system/nginx.service
cat > /usr/lib/systemd/system/nginx.service << EOF
[Unit]
Description=NGINX
After=syslog.target network.target
[Service]
Type=forking
PrivateTmp=yes
Restart=always
ExecStart=$installPath/sbin/nginx
ExecStop=/bin/kill -15 $MAINPID
[Install]
WantedBy=multi-user.target
EOF
    
else
    echo "已经存在nginx.service，请自行设置nginx的启动方式，开始退出"
    exit 1
fi

echo "设置开启重启"
systemctl daemon-reload
systemctl enable nginx
systemctl is-enabled nginx
echo "请使用：systemctl start nginx启动服务"
echo "请自行打开防火墙端口"



