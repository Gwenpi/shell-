功能说明：
配合crontab进行定时的mysql数据库备份，也可以进行单独备份

配置文件路径:
脚本路径下的conf目录

配置参数说明：
IS_ALL                  //true 全库备份,flase 备份DATABASES指定的数据库
USER                    //mysql用户名
PASSWORD                //mysql密码
HOST                    //备份的IP地址，例如：localhost
PORT                    //mysql端口
DATABASES               //指定备份的数据库，多库备份用"**"隔开，例如：test**test1
BACKUP_PATH             //备份的路径，例如：/home/workspace/backup/mysql
SUFFIX                  //备份文件的后缀名，例如：backup。备份文件使用后缀名是为了更好的识别，也为了防止备份路径填错后，防止因为设置保留时间而误删
IS_TIMING_DELETE        //true 设置定时删除，false 不进行设置
STORAGE_TIME            //备份文件保留的时间，例如：7

依赖说明：
yum install -y zip
需要安装msyql,因为要用到mysqldump,并配置环境变量

单独使用说明：
修改脚本路径的conf目录下的配置文件backup.conf。修改好参数后：
sh backupMysql.sh backup.conf
也可以新建配置文件，模仿backup.conf，并修改：
//注意配置文件名没有特殊要求，上面backup.conf中的".conf"后缀，只是为了好识别，也可以不用这个后缀
cp ./conf/backup.conf otherBackup
修改otherBackup之后再sh backupMysql.sh otherBackup

配合crontab使用说明：
crontab -e
配置命令如下：
//以下为每天凌晨三点进行备份。". /etc/profile;"的作用是，为了让crontab中接下连的shell有与当前系统一样的环境变量，这样配置好mysqldump之后，crontab也可以使用
0 3 * * * . /etc/profile;sh /脚本路径/backupMysql.sh backup.conf &> /脚本路径/backupMysql.log