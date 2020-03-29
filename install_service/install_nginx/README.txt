使用方法
将需要安装的tar.gz包放到与脚本相同的目录下，执行
sh install_nginx.sh

需要联网，会安装依赖pcre pcre-devel gcc zlib-devel
之后会配置nginx.service，并设置开机自启
请手动systemctl start nginx启动服务，并自行开启防火墙端口。