#!/bin/bash

echo " ****** Starting Script to Check critical Ambari Alets  ***** "

#######################################################################################################
#
#  This script will check for critical alerts on Ambari and report the same via email                ##
#
#######################################################################################################


. `dirname ${0}`/checkAlerts.properties

curr_date=`date +"%Y%m%d_%H%M%S"`


function check_ambari_server() {


   echo " Check and Start Ambari Server : "

   server_start=`ambari-server status |grep running|awk '{print $3}'`

   echo $server_start

   if [ "$server_start"  == "running" ]; then
       echo "Ambari server running already .. "
   else
       echo " Initiating ambari server start "
       ambari-server start
       sleep 30

       finished=0
       retries=0

       while [ $finished -ne 1 ]

       do
           server_start=`ambari-server status |grep running|awk '{print $3}'`
           echo $server_start

           if [ "$server_start"  == "running" ]; then

             finished=1
           fi


           sleep 5

           let retries=$retries+1

           if [[ $retries == 30 ]]
           then
              echo " Unable to Start Ambari Server. Please check the Ambari Server logs to determine the issue ... "
              exit 1
           fi

           echo " Polling for Ambari Server status $retries "
       done

   fi

}




function check_alert_status() {

        check_ambari_server

        alerts=`curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -X GET http://$AMBARI_SERVER:$AMBARI_SERVER_PORT/api/v1/clusters/${CLUSTER_NAME}/alerts?fields=*\&Alert/state=${CHECK_LEVEL}\&Alert/maintenance_state=OFF |grep 'component_name\|service_name\|text'`

        echo "$alerts" > alertStatus.dat

}



#### Main code Starts HERE ####

check_alert_status
