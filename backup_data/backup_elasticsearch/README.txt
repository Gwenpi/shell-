����˵����
���crontab���ж�ʱ��elasticsearch�������ݣ�Ҳ���Խ��е�������

�����ļ�·��:
�ű�·���µ�confĿ¼

���ò���˵����
IS_ALL                  //true ȫ��������,flase ����BACKUP_INDEXָ��������
SOURCE_URL              //��Ҫ���ݵ�����Դ�����磺http://127.0.0.1:9200
BACKUP_PATH             //���ݵ�·�������磺/home/workspace/backup/elasticsearch
BACKUP_INDEX            //��Ҫ���ݵ�����������������ʱ������������","���������磺test_index1,test_index2
LIMIT                   //ÿ�α��ݵ���������ͨ��Խ�󱸷�Խ�죬���������ܶ��������磺10000
SUFFIX                  //�����ļ��ĺ�׺�������磺backup�������ļ�ʹ�ú�׺����Ϊ�˸��õ�ʶ��ҲΪ�˷�ֹ����·�����󣬷�ֹ��Ϊ���ñ���ʱ�����ɾ
IS_TIMING_DELETE        //true ���ö�ʱɾ����false ����������
STORAGE_TIME            //�����ļ�������ʱ�䣬���磺7

����˵����
yum install -y zip
��Ҫ��װelasticdump,�����û�������

����ʹ��˵����
�޸Ľű�·����confĿ¼�µ������ļ�backup.conf���޸ĺò�����
sh backupElasticsearch.sh backup.conf
Ҳ�����½������ļ���ģ��backup.conf�����޸ģ�
//ע�������ļ���û������Ҫ������backup.conf�е�".conf"��׺��ֻ��Ϊ�˺�ʶ��Ҳ���Բ��������׺
cp ./conf/backup.conf otherBackup
�޸�otherBackup֮����sh backupElasticsearch.sh otherBackup

���crontabʹ��˵����
crontab -e
�����������£�
//����Ϊÿ���賿������б��ݡ�". /etc/profile;"�������ǣ�Ϊ����crontab�н�������shell���뵱ǰϵͳһ���Ļ����������������ú�elasticdump֮��crontabҲ����ʹ��
0 3 * * * . /etc/profile;sh /�ű�·��/backupElasticsearch.sh backup.conf &> /�ű�·��/backupElasticsearch.log