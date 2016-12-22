#!/bin/bash

export WCOLL=/root/all.hosts

pdsh "yum -y remove ranger\*"
pdsh "yum -y remove hive\*"
pdsh "yum -y remove tez\*"
pdsh "yum -y remove pig\*"
pdsh "yum -y remove storm\*"
pdsh "yum -y remove zookeeper\*"
pdsh "yum -y remove falcon\*"
pdsh "yum -y remove oozie\*"
pdsh "yum -y remove flume\*"
pdsh "yum -y remove sqoop\*"
pdsh "yum -y remove slider\*"
pdsh "yum -y remove spark\*"
pdsh "yum -y remove hadoop\*"
pdsh "yum -y remove bigtop\*"
pdsh "rm -rf /usr/hdp/2.5.0.0-1245/"
pdsh "rm -rf /usr/hdp/current"
pdsh "rm -rf /var/log/hadoop/*"