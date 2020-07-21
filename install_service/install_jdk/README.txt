使用方法:
将需要安装的jdk，或者openjdk包，放到脚本的相同目录下。
在install_jdk.conf中填写安装路径（路径为原先不存在的）
source install.sh

已测试的jdk包:
openjdk-8u41-b04-linux-x64-14_jan_2020.tar.gz
jdk-13.0.2_linux-x64_bin.tar.gz
jdk-8u241-linux-x64.tar.gz


涉及路径即文件
intall_jdk.conf中的安装路径
/etc/profile

安装解压完之后会判断/etc/profile中有没有JAVA_HOME,如果存在则会优先使用当前安装的JAVA_HOME