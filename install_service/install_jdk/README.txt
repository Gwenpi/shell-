使用方法:
将需要安装的jdk包，放到脚本的相同目录下。脚本会解压到安装目录的一个临时子目录。
然后在临时之目录下获取解压包的名字。最后在叫它取出到上级目录。
要求执行脚本的用户在安装目录下有创建目录的权限。
source install.sh



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