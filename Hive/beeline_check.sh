#!/bin/bash


echo "starting the script and file cleanup "


rm -f /tmp/beelineout_bw*.txt


sudo kinit -kt /etc/security/keytabs/hive.service.keytab hive/server1.us.xxxx-xxx.com@US.xxxx-xxx.com



nohup sudo beeline -u "jdbc:hive2://server1.us.xxxx-xxx.com:10000/;principal=hive/_HOST@AA.xxxx-xxx.com" -e "use hivetest;" > /tmp/beelineout_server1.txt  &
nohup sudo beeline -u "jdbc:hive2://server2.us.xxxx-xxx.com:10001/default;ssl=true;sslTrustStore=/etc/hive/conf/truststore.jks;trustStorePassword=password;transportMode=http;httpPath=cliservice;principal=hive/_HOST@AA.xxxx-xxx.com" -e "use hivetest;" > /tmp/beelineout_server2.txt  &


echo "Will sleep for 10 secs"


jobs -l

sleep 10

echo "Checking file after 10 secs "


output_server1=`cat /tmp/beelineout_server1.txt |grep 'No rows affected' |wc -l`
output_server2=`cat /tmp/beelineout_server2.txt |grep 'No rows affected' |wc -l`


##echo $output_server1
##echo $output_server2



if [ $output_server1 == 1 ]
then
   echo "Connection Successful on - server1 "
else
   echo "Bad connection on server1 - No response received  "
  
fi


if [ $output_server2 == 1 ]
then
   echo "Connection Successful on - server2 "
else
   echo "Bad connection on server2 - No response received   "
fi
