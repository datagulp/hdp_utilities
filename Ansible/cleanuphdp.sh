#!/bin/bash 

export HDPREPO=HDP-2.6
export UTILREPO=HDP-UTILS-1.1.0.22
export HDP_VERSION=2_6_5_0_292
export DNSNAME=field.hortonworks.com
export AMBARIREPO=ambari

# Clean up HDP repos 
hdplist=`ansible all -a "yumdb search from_repo $HDPREPO* $UTILREPO*" | egrep -v '(from_repo|^$)' |sort  -u |grep -v Loaded | grep -v $DNSNAME`

for comps in $hdplist; 
do 
    ansible all -a "yum -y remove $comps"
done

## Stop Ambari Agent and Server " 

ansible all -a "/usr/sbin/ambari-agent stop" 

ansible ambari -a "/usr/sbin/ambari-server stop" 

## Clean up all Ambari Repos 

amblist=`ansible all -a "yumdb search from_repo $AMBARIREPO*" | egrep -v '(from_repo|^$)' |sort  -u |grep -v Loaded | grep -v $DNSNAME`

for comps in $amblist;
do
    ansible all -a "yum -y remove $comps"
done

## Clean up all the Log files
ansible all -a "rm -rf /var/log/ambari*"
ansible all -a "rm -rf /var/log/falcon"
ansible all -a "rm -rf /var/log/flume"
ansible all -a "rm -rf /var/log/hadoop*"
ansible all -a "rm -rf /var/log/hive*"
ansible all -a "rm -rf /var/log/hst"
ansible all -a "rm -rf /var/log/knox"
ansible all -a "rm -rf /var/log/oozie"
ansible all -a "rm -rf /var/log/solr"
ansible all -a "rm -rf /var/log/zookeeper"


## Clean up hadoop logs 
ansible all -a "rm -rf /hadoop/*"
ansible all -a "rm -rf /hdfs/hadoop"
ansible all -a "rm -rf /hdfs/lost+found"
ansible all -a "rm -rf /hdfs/var"
ansible all -a "rm -rf /local/opt/hadoop"
ansible all -a "rm -rf /tmp/hadoop"
ansible all -a "rm -rf /usr/bin/hadoop"
ansible all -a "rm -rf /usr/hdp"
ansible all -a "rm -rf /var/hadoop"


## Clean up executables 
ansible all -a "rm -rf /var/run/ambari*"
ansible all -a "rm -rf /var/run/falcon"
ansible all -a "rm -rf /var/run/flume"
ansible all -a "rm -rf /var/run/hadoop*" 
ansible all -a "rm -rf /var/run/hbase"
ansible all -a "rm -rf /var/run/hive*"
ansible all -a "rm -rf /var/run/hst"
ansible all -a "rm -rf /var/run/knox"
ansible all -a "rm -rf /var/run/oozie" 
ansible all -a "rm -rf /var/run/webhcat"
ansible all -a "rm -rf /var/run/zookeeper"


## Clean up Lib Folders 
ansible all -a "rm -rf /usr/lib/ambari*"
ansible all -a "rm -rf /usr/lib/ams-hbase"
ansible all -a "rm -rf /var/lib/flume"
ansible all -a "rm -rf /var/lib/hadoop*" 
ansible all -a "rm -rf /var/lib/hive"
ansible all -a "rm -rf /var/lib/knox"
ansible all -a "rm -rf /var/lib/smartsense"
ansible all -a "rm -rf /var/lib/storm"
