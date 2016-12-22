#!/bin/bash

LOGFILE=/var/log/AmbariMgmtNode.log
echo "Ambari Management Node Script" >> $LOGFILE 

echo "Install Apache" >> $LOGFILE
yum install -y httpd >> $LOGFILE
chkconfig httpd on 

echo "Install NTP" >> $LOGFILE
yum install -y ntp >> $LOGFILE
chkconfig ntpd on >> $LOGFILE

yum install -y wget >> $LOGFILE
yum install -y nmap >> $LOGFILE
yum install -y zip >> $LOGFILE
yum install -y unzip >> $LOGFILE
yum erase -y snappy* >> $LOGFILE
yum install -y snappy-1.0.5* >> $LOGFILE
yum install -y pdsh >> $LOGFILE

echo "Format and Mount Volumes" >> $LOGFILE
mkfs -t ext4 /dev/xvdb >> $LOGFILE
mkdir /var/log/hadoop >> $LOGFILE
mount /dev/xvdb /var/log/hadoop >> $LOGFILE

mkfs -t ext4 /dev/xvdc >> $LOGFILE
mkdir -p /var/www/html >> $LOGFILE
mount /dev/xvdc /var/www/html >> $LOGFILE

mkfs -t ext4 /dev/xvdd >> $LOGFILE
mount /dev/xvdd /tmp >> $LOGFILE

echo "Add Mount Points to fstab" >> $LOGFILE
echo "/dev/xvdb /var/log/hadoop ext4 defaults 0 0" >> /etc/fstab >> $LOGFILE
echo "/dev/xvdc /var/www/html ext4 defaults 0 0" >> /etc/fstab >> $LOGFILE
echo "/dev/xvdd /tmp ext4 defaults 0 0" >> /etc/fstab >> $LOGFILE
echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg >> $LOGFILE

echo "Setup Ambari Repos" >> $LOGFILE
cd /var/www/html >> $LOGFILE
wget http://<repoURL>//MgmtNodes/HDP-UTILS-1.1.0.20-centos7.tar.gz >> $LOGFILE
wget http://<repoURL>//MgmtNodes/ambari-2.2.2.0-centos7.tar.gz >> $LOGFILE
tar -xzvf HDP-UTILS-1.1.0.20-centos7.tar.gz
tar -xzvf ambari-2.2.2.0-centos7.tar.gz
wget http://<repoURL>//MgmtNodes/HDP-2.4.2.0-centos7-rpm.tar >> $LOGFILE
tar -xvf HDP-2.4.2.0-centos7-rpm.tar

cd /etc/yum.repos.d
wget http://<repoURL>//MgmtNodes/HDP-UTILS.repo
wget http://<repoURL>//MgmtNodes/HDP.repo
wget http://<repoURL>//MgmtNodes/ambari.repo

echo "Install Mongo" >> $LOGFILE
wget http://<repoURL>//MgmtNodes/mongodb-org-3.2.repo >> $LOGFILE
yum install -y mongodb-org >> $LOGFILE

echo "Host Settings" >> $LOGFILE
echo "preserve_hostname: true" >> /etc/cloud/cloud.cfg

cd /etc
wget http://<repoURL>//AllNodes/rc.local -O /etc/rc.local >> $LOGFILE

echo never > /sys/kernel/mm/transparent_hugepage/enabled >> $LOGFILE
echo never > /sys/kernel/mm/transparent_hugepage/defrag >> $LOGFILE
setenforce 0 && sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config >> $LOGFILE

echo "Install JDK" >> $LOGFILE
cd /var/www/html >> $LOGFILE
wget http://<repoURL>//AllNodes/jdk-8u102-linux-x64.rpm >> $LOGFILE
rpm -ivh jdk-8u102-linux-x64.rpm >> $LOGFILE

echo "Change Swappiness" >> $LOGIFLE
sysctl vm.swappiness=1 >> $LOGFILE

echo "*                soft    nofile          65536" >> /etc/security/limits.conf >> $LOGFILE
echo "*                hard    nofile          65536" >> /etc/security/limits.conf >> $LOGFILE

echo "End of Script" >> $LOGFILE
