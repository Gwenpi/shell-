����˵��
��װelasticsearch������log��data��·��,Xmx��Xms��С��
���һЩ���������á�

������
elasticsearch��Ӧ�汾ָ���Ķ�Ӧ�汾��jdk��������а�װ

ʹ�÷���
1.����װ���ŵ��ű�·����,�ű�·����ֻ�����һ��es��װ����Ȼ��ű���ָ���ð���
2.����install_elasticsearch.conf���û���������
#���������������÷�������������̨ͬ������̨ES����
serverName=elasticsearch-6.3.2
#http���ʶ˿�
httpPort=9200
#��Ⱥ�ڲ�ͨ�Ŷ˿�
tcpTransport=9300
#���²������õ�ʱJVM�Ķѿռ��С
XmsSize=2
XmxSize=2
3.��ʼ��װ��
sh install_elasticsearch.sh

4.����|ֹͣ|����
service ���������õķ����� start|stop|restart


�Ѿ����ԵĻ���&�汾
CentOS7&elasticsearch-6.3.2

