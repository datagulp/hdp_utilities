#!/bin/bash
LOGFILE=/var/log/MasterNodes.log
HOSTNAME="hdp.ganeshrj.com"
SHORTNM=`echo $HOSTNAME|cut -d"." -f1`

echo "Begin Master Node Script" >> $LOGFILE

## Applicable only for RHEL/CentOS 7 
hostnamectl  set-hostname $HOSTNAME --static

echo "Install NTP" >> $LOGFILE
yum install -y ntp >> $LOGFILE
chkconfig ntpd on >> $LOGFILE
yum install -y httpd* >> $LOGFILE
service httpd start >> $LOGFILE
yum install -y wget >> $LOGFILE
yum install -y nmap >> $LOGFILE
yum install -y zip >> $LOGFILE
yum install -y unzip >> $LOGFILE
yum erase -y snappy* >> $LOGFILE

wget http://public-repo-1.hortonworks.com/ambari/centos7/2.x/updates/2.2.2.0/ambari.repo -O /etc/yum.repos.d/ambari.repo
wget http://public-repo-1.hortonworks.com/HDP/centos7/2.x/updates/2.4.2.0/hdp.repo -O /etc/yum.repos.d/hdp.repo

yum -y install ambari-server
yum -y install ambari-agent
yum install -y snappy-1.0.5* >> $LOGFILE

#echo "Install JDK" >> $LOGFILE
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u102-b14/jdk-8u102-linux-x64.rpm" -O /tmp/jdk-8u102-linux-x64.rpm
## JDK 1.7.51 link --> http://download.oracle.com/otn/java/jdk/7u55-b13/jdk-7u55-linux-i586.rpm
cd /tmp

rpm -ivh jdk-8u102-linux-x64.rpm

yum -y install mysql-connector-java

echo "Host Settings" >> $LOGFILE
echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg

echo "Changing rc.local file " >> $LOGFILE

echo " " >> /etc/rc.local
echo "if test -f /sys/kernel/mm/redhat_transparent_hugepage/enabled; then " >> /etc/rc.local
echo "  echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local
echo "fi"  >> /etc/rc.local

echo " " >> /etc/rc.local
echo "if test -f /sys/kernel/mm/redhat_transparent_hugepage/defrag; then " >> /etc/rc.local
echo "  echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.local
echo "fi"  >> /etc/rc.local

echo never > /sys/kernel/mm/transparent_hugepage/enabled >> $LOGFILE
echo never > /sys/kernel/mm/transparent_hugepage/defrag >> $LOGFILE
setenforce 0 && sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config >> $LOGFILE

echo "Change Swappiness" >> $LOGFILE
sysctl vm.swappiness=1 >> $LOGFILE

echo "*                soft    nofile          65536" >> /etc/security/limits.conf >> $LOGFILE
echo "*                hard    nofile          65536" >> /etc/security/limits.conf >> $LOGFILE

ipaddr=`ifconfig |grep inet | head -1 |awk '{print $2}'`

echo "$ipaddr $HOSTNAME  $SHORTNM"  >> /etc/hosts

echo "End of Master Node Script" >> $LOGFILE
