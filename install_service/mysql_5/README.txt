使用前提:
1.安装包必须是.tar.gz结尾的，这个是写死的没有其余的判断
2.mysql5版本的.tar.gz包放在和install_mysql_5.sh相同的目录下

环境：
CentOS7

已经测试的版本：
mysql 5.7.28


mysql5版本需要的依赖：
1.libaio库
2.net-tools

使用说明:
sh install_mysql_5.sh
最后会提示要不要更改root密码和创建远程连接用户。按提示走就行。


所涉及的目录:
主目录：/usr/local/mysql
主目录下：log,etc,run
临时目录：/usr/local/mysql_temp_wp
data目录：/data/mysql/data
binlogs目录：/data/mysql/binlogs

创建的文件：
/usr/lib/systemd/system/mysqld.service

删除的文件：
/etc/my.cnf

开放的端口:你输入的端口

大概流程：
source insttall_mysql_5.sh
输入mysql需要开放的端口号。
安装完之后，会提示是否需要修改原始的root密码，和是否需要创建一个远程连接用户。

一般空机器安装是不会发送什么问题。
如果是之前安装过mysql,可能会出现目录冲突


