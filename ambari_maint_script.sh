#!/bin/bash

echo "Started"

#############################################################
# Functionalites added: 
# --------------------
#
# 1. START Services 
# 2. STOP Services
# 3. RESTART Services
#
#
# To be added: 
# ------------ 
# 4. SRVCHK Run Service Checks on all the service 
#
#############################################################


. `dirname ${0}`/maint_ambari_services.properties

STARTSTOPLIST=/home/ambari/maintenance_scripts/startstopparms.txt
TEMP_FILE=/tmp/ambari_api_temp.file



function wait() { 

finished=0
retries=0
 
while [ $finished -ne 1 ]
 
do
   str=$(curl -s -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/services/$1)
   if [[ $str == *"$2"* ]] || [[ $str == *"Service not found"* ]]
   then
       finished=1
   fi
   sleep 6

   let retries=$retries+1 

   if [[ $retries == 30 ]] 
   then
      echo " Unable to start the service ... proceeding to NEXT one " 
      return
   fi 

   echo $1 " Polling for status ...$retries"
done

}

function service_check() { 


     echo " Running Service Check Components .... "

     for service in $ordered_services
     do
         echo "RUNNING SERVICE CHECK FOR " $service " Service ...."

         curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" : "Stopping service via REST before Reboot"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/services/$service


         echo $service " Service Check started. Please logon on to Ambari to view results "

     done

}

function stop_services() { 
  
     echo " Stopping Components .... " 

     for service in $ordered_services
     do 
         echo "STOPPING " $service " Service ...."
      
         ##comment="Stop $service via REST"
         ##echo $comment

         curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" : "Stopping service via REST before Reboot"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/services/$service
 
        
         wait "$service" "INSTALLED"
      
         echo $service " Stopped Successfully .... "

     done        

}


function start_services() { 


     echo " Starting Components .... "

     for service in $ordered_services
     do
         echo "STARTING " $service " Service ...."

         ##comment="Start $service via REST"
         ##echo $comment

         curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" : "Starting service via REST after Reboot"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/services/$service


         wait "$service" "STARTED"

         echo $service " Started Successfully .... "

     done

}

prep_start() { 

   echo " Preparing to " $1 " services on " $CLUSTER_NAME


   services=`curl -H "X-Requested-By: ambari" -X GET -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD "http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/services?fields=ServiceInfo&ServiceInfo/maintenance_state=OFF&ServiceInfo/state=INSTALLED" |grep service_name|cut -d: -f 2| sed s/\"//g|sed s/\,//g`

   echo $services

   if [ -f "$TEMP_FILE" ];
   then 
       echo "Temp File exists ... Cleaning up... "

       rm -f $TEMP_FILE
       touch $TEMP_FILE 
   else 
       touch $TEMP_FILE 
   fi


   for ser in $services
   do
       grep $ser $STARTSTOPLIST >> $TEMP_FILE
   done

   ordered_services=`cat $TEMP_FILE |sort|cut -d' ' -f 2`


   srv_cnt=`echo $ordered_services | wc -w`

   if [ $srv_cnt == 0 ]; then

       echo "                                      "
       echo "All services are Up and Running. Nothing to Start...."
       echo "                                      "
       exit 1
   fi

   echo "Services Stopped : " $ordered_services " --- Will be Started ---- "

   start_services ordered_services

} 

prep_stop() {

   echo " Preparing to " $1 " services on " $CLUSTER_NAME

   services=`curl -H "X-Requested-By: ambari" -X GET -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD "http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/services?fields=ServiceInfo&ServiceInfo/maintenance_state=OFF&ServiceInfo/state=STARTED" |grep service_name|cut -d: -f 2| sed s/\"//g|sed s/\,//g`



   if [ -f "$TEMP_FILE" ];
   then
       echo "Temp File exists ... Cleaning up... "

       rm -f $TEMP_FILE
       touch $TEMP_FILE 
   else
       touch $TEMP_FILE
   fi


   for ser in $services
   do
       grep $ser $STARTSTOPLIST >> $TEMP_FILE
   done

   ordered_services=`cat $TEMP_FILE |sort -r|cut -d' ' -f 2`


   srv_cnt=`echo $ordered_services | wc -w`


   if [ $srv_cnt == 0 ]; then

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


   if [ $RUNNING_APPS==0 ]; then

      echo "Number of Running Applications  : " $RUNNING_APPS
      echo "                                  "
      echo "Obtaining Running Components ....."
      echo "                                  "

   else

      echo "Please make sure the running applications are stopped or gracefully shutdown..."
      exit 1

   fi

   echo "Services Running : " $ordered_services " --- Will be Stopped ---- "


   stop_services ordered_services


}


##########################################################################################################
################################## START of Main Code ####################################################
##########################################################################################################


if [ "$1" == "STOP" ]; then 

   prep_stop


   echo "                                      " 
   echo "*****All Services STOPPED Successfully *****" 
   echo "                                      " 

elif [ "$1" == "START" ]; then 

   prep_start

   start_services ordered_services

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


elif [ "$1" == "SVCCHK" ]; then

   echo " Preparing to " $1 " services on " $CLUSTER_NAME

   echo " Construction in Progress.... "

else
    
   echo "                                                                        "
   echo "                                                                        "
   echo "Usage: ./maint_ambari_services.sh [START] [STOP] [RESTART] [SVCCHK]     "
   echo "                                                                        "
   echo "                                                                        "
   exit 1 

fi 

## Cleanup temp file

rm -f temp.file

