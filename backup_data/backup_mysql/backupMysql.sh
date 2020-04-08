#!/bin/bash

script_dir="$(dirname -- "$(readlink -f -- "$0")")"
#配置文件名
configureName=$1

#这里的配置文件路径是固定的脚本路径下的conf目录下
configurePath=$script_dir/conf/$configureName

if [ ! -e $configurePath ];then
    echo "不存在指定的配置文件，请在脚本路径的conf目录下创建配置文件,开始退出"
    exit 1
fi

function getParam()
{
    paramName=$1
    temp=$(cat $configurePath|grep $paramName)
    if [ "$temp" = "" ];then
        echo "不存在${paramName}参数，请检查配置，开始退出"
        exit 1
    fi
    param=${temp#*=}
    if [ "$param" = "" ];then
        echo "参数为空，请检查配置，开始退出"
        exit 1
    fi
    eval $1=$param
}

#获取配置信息
getParam IS_ALL
getParam USER
getParam PASSWORD
getParam HOST
getParam PORT
#需要备份的数据库
getParam DATABASES
#备份路径
getParam BACKUP_PATH
#备份的后缀名
getParam SUFFIX

#是否定时删除
getParam IS_TIMING_DELETE
if [ "$IS_TIMING_DELETE" = "true" ];then
    #保留时间
    getParam STORAGE_TIME
fi

#不存在备份路径,则创建
if [ ! -d $BACKUP_PATH ];then
    mkdir -p $BACKUP_PATH
fi

date=$(date +%Y%m%d)


if [ "$IS_ALL" = "true" ];then
    backupPath="$BACKUP_PATH/${date}_all.${SUFFIX}"
else
    #如果存在多库备份，则将多库之间的空格用下划线代替
    backupPath="$BACKUP_PATH/${date}_${DATABASES//\*\*/_}.${SUFFIX}"
fi

#备份并压缩
if [ "$IS_ALL" = "true" ];then
    mysqldump -u$USER -p$PASSWORD --host=$HOST --port=$PORT --all-databases | zip > ${backupPath}
else
    #如果存在多库备份则将**换为空格
    mysqldump -u$USER -p$PASSWORD --host=$HOST --port=$PORT --databases ${DATABASES//\*\*/ } | zip > ${backupPath}
fi

#压缩
#zip ${backupPath}.zip $backupPath


if [ "$IS_TIMING_DELETE" = "true" ];then
    #定时删除,删除在7天之前修改的，后缀名为${SUFFIX}的文件。加后缀名是为了防止路径错时的误删
    find $BACKUP_PATH -type f -name "*.${SUFFIX}" -mtime +${STORAGE_TIME} -exec rm {} \;
fi