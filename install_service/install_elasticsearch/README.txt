功能说明
安装elasticsearch，设置log和data的路径,Xmx和Xms大小。
完成一些基本的配置。

依赖：
elasticsearch对应版本指定的对应版本的jdk，这个自行安装

使用方法
1.将安装包放到脚本路径下,脚本路径下只允许放一个es安装包，然后脚本会指定该包。
2.配置install_elasticsearch.conf配置基础的设置
#服务名，用于配置服务自启，区别同台机器两台ES服务
serverName=elasticsearch-6.3.2
#http访问端口
httpPort=9200
#集群内部通信端口
tcpTransport=9300
#以下参数设置的时JVM的堆空间大小
XmsSize=2
XmxSize=2
3.开始安装：
sh install_elasticsearch.sh

4.启动|停止|重启
service 配置中设置的服务名 start|stop|restart


已经测试的环境&版本
CentOS7&elasticsearch-6.3.2

