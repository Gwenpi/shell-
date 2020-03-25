使用方法:
将需要安装的jdk包，放到脚本的相同目录下。
source install.sh

已测试的jdk包:
openjdk-8u41-b04-linux-x64-14_jan_2020.tar.gz
jdk-13.0.2_linux-x64_bin.tar.gz
jdk-8u241-linux-x64.tar.gz


涉及路径即文件
intall_jdk.conf中的安装路径
/etc/profile

安装解压完之后会判断/etc/profile中有没有JAVA_HOME
如果不存在就往里添加JAVA_HOME并重置PATH

建议在配置之间，初始化的环境变量PATH,因为如果之前配置过其他的环境变量，会导致PATH重复之前的环境变量

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
export MYSQL_HOME=xxx
export NGINX_HOME=xxx
export JAVA_HOME=xxx
export PATH=${PATH}:${MYSQL_HOME}/bin:${NGINX_HOME}/bin:${JAVA_HOME}/bin