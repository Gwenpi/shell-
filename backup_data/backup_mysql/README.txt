����˵����
���crontab���ж�ʱ��mysql���ݿⱸ�ݣ�Ҳ���Խ��е�������

�����ļ�·��:
�ű�·���µ�confĿ¼

���ò���˵����
IS_ALL                  //true ȫ�ⱸ��,flase ����DATABASESָ�������ݿ�
USER                    //mysql�û���
PASSWORD                //mysql����
HOST                    //���ݵ�IP��ַ�����磺localhost
PORT                    //mysql�˿�
DATABASES               //ָ�����ݵ����ݿ⣬��ⱸ����"**"���������磺test**test1
BACKUP_PATH             //���ݵ�·�������磺/home/workspace/backup/mysql
SUFFIX                  //�����ļ��ĺ�׺�������磺backup�������ļ�ʹ�ú�׺����Ϊ�˸��õ�ʶ��ҲΪ�˷�ֹ����·�����󣬷�ֹ��Ϊ���ñ���ʱ�����ɾ
IS_TIMING_DELETE        //true ���ö�ʱɾ����false ����������
STORAGE_TIME            //�����ļ�������ʱ�䣬���磺7

����˵����
yum install -y zip
��Ҫ��װmsyql,��ΪҪ�õ�mysqldump,�����û�������

����ʹ��˵����
�޸Ľű�·����confĿ¼�µ������ļ�backup.conf���޸ĺò�����
sh backupMysql.sh backup.conf
Ҳ�����½������ļ���ģ��backup.conf�����޸ģ�
//ע�������ļ���û������Ҫ������backup.conf�е�".conf"��׺��ֻ��Ϊ�˺�ʶ��Ҳ���Բ��������׺
cp ./conf/backup.conf otherBackup
�޸�otherBackup֮����sh backupMysql.sh otherBackup

���crontabʹ��˵����
crontab -e
�����������£�
//����Ϊÿ���賿������б��ݡ�". /etc/profile;"�������ǣ�Ϊ����crontab�н�������shell���뵱ǰϵͳһ���Ļ����������������ú�mysqldump֮��crontabҲ����ʹ��
0 3 * * * . /etc/profile;sh /�ű�·��/backupMysql.sh backup.conf &> /�ű�·��/backupMysql.log