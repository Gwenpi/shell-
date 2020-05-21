使用说明：
在install_mysql_8.conf配置文件中配置安装位置,data,log位置,还有端口号,将安装包放在与脚本相同的路径下。
脚本会将/etc/my.cnf改名,之后在安装位置下创建新的my.cnf，并设置一些基本配置。

需要的依赖：
libaio
联网条件脚本会自动安装,没有联网的话,请自行安装依赖

安装:
source install.sh

启动命令:
service mysql start
