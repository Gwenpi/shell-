#! /bin/bash

script_dir="$(dirname -- "$(readlink -f -- "$0")")"

isAlone=$(ls ${script_dir}|grep -E "^nginx"|grep -E "gz$"|wc -l)

if [ "$isAlone" != "1" ];then
    echo "��ű���ͬ·���´��ڶ����װ��,��ȷ�Ϻ�������Ҫ��װ�İ�װ������ʼ�˳�"
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

#��װ����������Ժ�Ҫ�ĳ����߰�װ
yum install -y pcre pcre-devel gcc zlib-devel

temp=$(cat $script_dir/install_nginx.conf|grep installPath)
installPath=${temp#*=}

unpackDir=$(ls -d ${script_dir}/*/)
cd $unpackDir
./configure --prefix=$installPath && make && make install
if [ "$?" != "0" ];then
    echo "����ʧ�ܣ��������������󣬿�ʼ�˳�"
    exit 1
fi

ls /usr/lib/systemd/system/nginx.service

if [ "$?" != "0" ];then
    echo "��ʼ����systemctl ����"
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
    echo "�Ѿ�����nginx.service������������nginx��������ʽ����ʼ�˳�"
    exit 1
fi

echo "���ÿ�������"
systemctl daemon-reload
systemctl enable nginx
systemctl is-enabled nginx
echo "��ʹ�ã�systemctl start nginx��������"
echo "�����д򿪷���ǽ�˿�"



