#!/bin/bash

script_dir="$(dirname -- "$(readlink -f -- "$0")")"
#�����ļ���
configureName=$1

#����������ļ�·���ǹ̶��Ľű�·���µ�confĿ¼��
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

#��ȡ������Ϣ
getParam IS_ALL
getParam USER
getParam PASSWORD
getParam HOST
getParam PORT
#��Ҫ���ݵ����ݿ�
getParam DATABASES
#����·��
getParam BACKUP_PATH
#���ݵĺ�׺��
getParam SUFFIX

#�Ƿ�ʱɾ��
getParam IS_TIMING_DELETE
if [ "$IS_TIMING_DELETE" = "true" ];then
    #����ʱ��
    getParam STORAGE_TIME
fi

#�����ڱ���·��,�򴴽�
if [ ! -d $BACKUP_PATH ];then
    mkdir -p $BACKUP_PATH
fi

date=$(date +%Y%m%d)


if [ "$IS_ALL" = "true" ];then
    backupPath="$BACKUP_PATH/${date}_all.${SUFFIX}"
else
    #������ڶ�ⱸ�ݣ��򽫶��֮��Ŀո����»��ߴ���
    backupPath="$BACKUP_PATH/${date}_${DATABASES//\*\*/_}.${SUFFIX}"
fi

#���ݲ�ѹ��
if [ "$IS_ALL" = "true" ];then
    mysqldump -u$USER -p$PASSWORD --host=$HOST --port=$PORT --all-databases | zip > ${backupPath}
else
    #������ڶ�ⱸ����**��Ϊ�ո�
    mysqldump -u$USER -p$PASSWORD --host=$HOST --port=$PORT --databases ${DATABASES//\*\*/ } | zip > ${backupPath}
fi

#ѹ��
#zip ${backupPath}.zip $backupPath


if [ "$IS_TIMING_DELETE" = "true" ];then
    #��ʱɾ��,ɾ����7��֮ǰ�޸ĵģ���׺��Ϊ${SUFFIX}���ļ����Ӻ�׺����Ϊ�˷�ֹ·����ʱ����ɾ
    find $BACKUP_PATH -type f -name "*.${SUFFIX}" -mtime +${STORAGE_TIME} -exec rm {} \;
fi