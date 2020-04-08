#!/bin/bash

script_dir="$(dirname -- "$(readlink -f -- "$0")")"
#�������ļ��л�ȡ��Ҫ���ݵ����ݿ����Ϣ����������������㶨ʱ���ݶ�̨���ݿ������
configureName=$1

#����������ļ�·���ǹ̶��Ľű�·���µ�conf
configurePath=$script_dir/conf/$configureName

if [ ! -e $configurePath ];then
    echo "������ָ���������ļ������ڽű�·����confĿ¼�´��������ļ�,��ʼ�˳�"
    exit 1
fi

function getParam()
{
    paramName=$1
    temp=$(cat $configurePath|grep $paramName)
    if [ "$temp" = "" ];then
        echo "������${paramName}�������������ã���ʼ�˳�"
        exit 1
    fi
    param=${temp#*=}
    if [ "$param" = "" ];then
        echo "����Ϊ�գ��������ã���ʼ�˳�"
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

#��ʱɾ��
if [ "$IS_TIMING_DELETE" = "true" ];then
    find $BACKUP_PATH -type f -name "*.${SUFFIX}" -mtime +${STORAGE_TIME} -exec rm {} \;
fi