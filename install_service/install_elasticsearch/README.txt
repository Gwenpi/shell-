使用方法
sh install_elasticsearch.sh

涉及的目录:
install_elasticsearch.conf中设置的目录

相关更改:
添加elasticsearch用户和用户组
并修改你设置的ES根目录的chown为elasticsearch:elasticsearch

之后会对ES做一些简单的配置，就是单点ES的配置。让你可以直接启动。
如果要做ES集群，请自行更改配置。
