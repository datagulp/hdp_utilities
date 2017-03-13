#!/bin/bash

echo "Started"

#############################################################
# Functionalites added:
# --------------------
#
# 1. START Services
# 2. STOP Services
# 3. RESTART Services
# 4. FORCESTOP Services
#
#############################################################


. `dirname ${0}`/ambari_maint_script.properties


function wait() {

finished=0
retries=0
status="STARTED"

if [ "$1" == "STOP" ]; then
   checkval=0
   sleeptime=10
fi


if [ "$1" == "START" ]; then
   checkval=5
   sleeptime=20
fi

while [ $finished -ne 1 ]

do
   serv=`curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD  -H "X-Requested-By: ambari" -X GET  http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/services/?fields=ServiceInfo/state | grep $status  |wc -l`

   echo $serv " ~~~~ "  $checkval

   if [ $serv == $checkval ]; then
      finished=1
   fi

   sleep $sleeptime

   let retries=$retries+1

   if [[ $retries == 30 ]]
   then
      echo " Unable to start all the service ... Please look into Ambari console for further logs "
      return
   fi

   echo " Polling for status $1 ... $retries -- services Pending : $serv ..."
done

if [ $finished == 1 ]; then

   if [ "$1" == "START" ]; then

       echo " $serv started successfully ... Please logon to Ambari and monitor rest of the services if they are up "
   else
       echo " All services $1 successfully "
   fi
fi

}



function service_check() {


     echo " Running Service Check Components  from payload file .... "

     curl -ivk -H "X-Requested-By: ambari" -u  $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD  -X POST -d @payload.txt http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/request_schedules

}

function stop_services() {

     echo " Stopping Components .... "

     curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stopping via Ambari Maintenance Script REST API"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/services

     wait  "STOP"

}


function start_services() {


     echo " Starting Components .... "

     curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Starting via Ambari Maintenance Script REST API"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/services

     wait  "START"
}

prep_start() {

   echo " Preparing to " $1 " services on " $CLUSTER_NAME


   services=`curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD  -H "X-Requested-By: ambari" -X GET  http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/services/?fields=ServiceInfo/state | grep STARTED  |wc -l`

   echo $services

   if [ $services == 0 ]; then

       echo "                                      "
       echo "All services are in Stopped State. Will initiate a START Though  ..."
       echo "                                      "

   else

       echo "                                      "
       echo "$services are already started.  Will initiate a START Though  ..."
       echo "                                      "

   fi


   start_services

}

prep_stop() {

   echo " Preparing to " $1 " services on " $CLUSTER_NAME


   services=`curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD  -H "X-Requested-By: ambari" -X GET  http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/services/?fields=ServiceInfo/state | grep STARTED  |wc -l`


   if [ $services == 0 ]; then

       echo "                                      "
       echo "All services are in Stopped State. Nothing to STOP ..."
       echo "                                      "


       if [ "$1" == "RESTART" ]; then
          echo "Proceeding with STARTING the components"
          return
       else
          exit 1
       fi
   fi

   RUNNING_APPS=`curl -X GET http://$RM_SERVER:8088/ws/v1/cluster/appstatistics?states=running | cut -d, -f 3 | cut -d: -f 2 | sed s/}]}}//g`

   echo $RUNNING_APPS

   if [ $RUNNING_APPS == 0 ]; then

      echo "Number of Running Applications  : " $RUNNING_APPS
      echo "                                  "

   else

     if [ "$1" == "FORCESTOP" ]; then
        echo " There are $RUNNING_APPS application(s) running. Forcing a STOP on the Cluster "
     else
        echo "There are $RUNNING_APPS application(s) running. Please make sure the running applications are stopped or gracefully shutdown..."
      exit 1
     fi

   fi

   stop_services


}


##########################################################################################################
################################## START of Main Code ####################################################
##########################################################################################################


if [ "$1" == "STOP" ]; then

   prep_stop "$1"


   echo "                                      "
   echo "*****All Services STOPPED Successfully *****"
   echo "                                      "

elif [ "$1" == "START" ]; then

   prep_start

   echo "                                      "
   echo "***All Services STARTED successfully ****"
   echo "                                      "

elif [ "$1" == "RESTART" ]; then

   echo " Preparing to " $1 " services on " $CLUSTER_NAME

   prep_stop $1

   echo "                                      "
   echo "***All Services STOPPED successfully ****"
   echo "                                      "


   prep_start $1

   echo "                                      "
   echo "***All Services RESTARTED successfully ****"
   echo "                                      "

elif [ "$1" == "FORCESTOP" ]; then

   prep_stop "$1"


   echo "                                      "
   echo "*****All Services STOPPED Successfully *****"
   echo "                                      "

else

   echo "                                                                        "
   echo "                                                                        "
   echo "Usage: ./maint_ambari_services.sh [START] [STOP] [RESTART] [FORCESTOP]  "
   echo "                                                                        "
   echo "                                                                        "
   exit 1

fi
