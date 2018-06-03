#!/bin/bash 

export HDPREPO=HDP-2.6
export UTILREPO=HDP-UTILS-1.1.0.22
export HDP_VERSION=2_6_5_0_292
export DSNNAME=field.hortonworks.com
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
ansible all -a "rm -rf /var/log/ambari-agent"
ansible all -a "rm -rf /var/log/ambari-metrics-grafana"
ansible all -a "rm -rf /var/log/ambari-metrics-monitor"
ansible all -a "rm -rf /var/log/ambari-server"
ansible all -a "rm -rf /var/log/falcon"
ansible all -a "rm -rf /var/log/flume"
ansible all -a "rm -rf /var/log/hadoop"
ansible all -a "rm -rf /var/log/hadoop-mapreduce"
ansible all -a "rm -rf /var/log/hadoop-yarn"
ansible all -a "rm -rf /var/log/hive"
ansible all -a "rm -rf /var/log/hive-hcatalog"
ansible all -a "rm -rf /var/log/hive2"
ansible all -a "rm -rf /var/log/hst"
ansible all -a "rm -rf /var/log/knox"
ansible all -a "rm -rf /var/log/oozie"
ansible all -a "rm -rf /var/log/solr"
ansible all -a "rm -rf /var/log/zookeeper"
