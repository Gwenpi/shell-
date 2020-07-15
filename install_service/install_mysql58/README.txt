使用说明：
在install_mysql_58.conf配置文件中配置安装位置,data,log位置,还有端口号,将安装包放在与脚本相同的路径下。

需要的依赖：
libaio
libnuma.so.1
联网条件脚本会自动安装，没有联网的话，请自行安装依赖

配置说明：
#安装路径
installPath=/home/workspace/mysql
#log路径
logPath=/home/workspace/mysql/log
#data路径
dataPath=/home/workspace/mysql/data
#端口
port=3306
#服务名
serverName=mysql

安装:
source install.sh


启动命令：
service 服务名 start


涉及目录&文件：
配置文件中的目录
/etc/init.d/服务名
备份(改名):
/etc/my.cnf

如果安装失败：
自行删除涉及的目录和文件即可
并将备份改回来

已经测试的mysql版本：
mysql-8.0.20-linux-glibc2.12-x86_64.tar.xz
mysql-5.7.30-linux-glibc2.12-x86_64.tar.gz
