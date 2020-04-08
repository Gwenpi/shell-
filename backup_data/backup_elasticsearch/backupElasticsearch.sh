#!/bin/bash

script_dir="$(dirname -- "$(readlink -f -- "$0")")"
#从配置文件中获取需要备份的数据库的信息，用这个方法来满足定时备份多台数据库的需求
configureName=$1

#这里的配置文件路径是固定的脚本路径下的conf
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

getParam SOURCE_URL
getParam BACKUP_PATH
getParam IS_ALL
getParam BACKUP_INDEX
getParam LIMIT
getParam SUFFIX
getParam IS_TIMING_DELETE
if [ "$IS_TIMING_DELETE" = "true" ];then
    getParam STORAGE_TIME
fi

if [ ! -d $BACKUP_PATH ];then
    mkdir -p $BACKUP_PATH
fi

date=$(date +%Y%m%d)

if [ "$IS_ALL" = "true" ];then
    outputPath=$BACKUP_PATH/${date}_all.${SUFFIX}
else
    outputPath=$BACKUP_PATH/${date}_${BACKUP_INDEX}.${SUFFIX}
fi

if [ "$IS_ALL" = "true" ];then
    elasticdump --input=$SOURCE_URL --output=$ --all=true --limit=$LIMIT | zip > $outputPath
else
    elasticdump --input=${SOURCE_URL}/${BACKUP_INDEX} --output=$ --limit=$LIMIT | zip > $outputPath
fi

#定时删除
if [ "$IS_TIMING_DELETE" = "true" ];then
    find $BACKUP_PATH -type f -name "*.${SUFFIX}" -mtime +${STORAGE_TIME} -exec rm {} \;
fi