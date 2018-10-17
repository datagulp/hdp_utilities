### Copyright @Ganesh Rajagopal

#!/bin/bash

echo "Started"

########################################################################################
# Functionalites added:
# --------------------
#
# 1. STOP the sevices, delete them and Take out the node.
# 2. ADD the slave nodes to cluster and DN, NM and RS and (if Hbase Exists) START Services
#
#######################################################################################


. `dirname ${0}`/ambari_maint_script.properties


function wait() {

finished=0
retries=0

while [ $finished -ne 1 ]

do
   str=$(curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X GET http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/hosts/$SLAVE_NODE?fields=host_components/* |grep "\"state\"" |grep $1 |wc -l)
   if [[ $str == "0" ]]
   then
       echo " All services Stopped successfully ... "
       finished=1
   fi
   sleep 6

   let retries=$retries+1

   if [[ $retries == 30 ]]
   then
      echo " Services are still in $1 state ... Please check the console ... "
      return "$finished"
   fi

   echo $1 " Polling for status $1 - Retries $retries - Components $1:  $str ***"
done

}




function delete_node {

    echo " *** In Delete Node Function *** "

    delnode=$(curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X GET http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/hosts/$SLAVE_NODE|grep "\"status\" : 404"|wc -l)


   if [[ $delnode == "1" ]]
   then
      echo " The  $SLAVE_NODE has been removed from the cluster already"
   else
      curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X DELETE http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/hosts/$SLAVE_NODE

      sleep 6

      delnode1=$(curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X GET http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/hosts/$SLAVE_NODE|grep "\"status\" : 404"|wc -l)

      if [[ $delnode1 == "1" ]]
      then
         echo " The node $SLAVE_NODE has been removed from the cluster Successfully  "
         echo " Please check the Ambari Console and Initiate  HDFS Re-balancer script  ... "
      else
         echo " ###  $SLAVE_NODE has not been deleted from the cluster ... Please check the Ambari Console to review error message !!! "
      fi
    fi

}


function delete_comps {

   echo " ***** In function Delete Comps ***** "

   delcomp=$(curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X GET http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/hosts/$SLAVE_NODE/host_components/ |grep "component_name"|wc -l)

   if [[ $delcomp == "0" ]]
   then
      echo " No components to delete in $SLAVE_NODE"
   else
      curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X DELETE http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/hosts/$SLAVE_NODE/host_components/

      sleep 6

      delcomp1=$(curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X GET http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/hosts/$SLAVE_NODE/host_components/ |grep "component_name"|wc -l)

      if [[ $delcomp1 == "0" ]]
      then
         echo " All Components on $SLAVE_NODE delete Successfully  "
         echo " Preparing to Delete the $SLAVE_NODE from the $CLUSTER_NAME ... "

         delete_node

      else
         echo " ### $delcomp1 Components NOT deleted in  $SLAVE_NODE... Please check the Ambari Console to review error message !!! "
      fi

   fi

}


function start_installed_services {

       echo "Starting Insalled Services on  $SLAVE_NODE "

       curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"HostRoles": {"state": "STARTED"}}'   http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/hosts/$SLAVE_NODE/host_components/


       echo "Initiated Startup of All the services on $SLAVE_NODE. Please refer to Ambari UI for further logs and errors .. "

}


function add_slave_comps {

 ## This function will add Datanode, NodeManager, Metrics Monitor (and Regional Server if HBASE Service exists) to the new slave node and start them up.
 ## The slave component will be replicated from an existing Slave node which is CLONE_NODE in the parmamer file.

   echo " In add_slave_comps function ... "

   services=`curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD  -H "X-Requested-By: ambari" -X GET "http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/hosts/${CLONE_NODE}/host_components" |grep component_name|cut -d: -f 2| sed s/\"//g|sed s/\,//g`

   serv=`echo "$services"`

   echo " Following services will be added to the ${SLAVE_NODE} " $serv

   for ser in $serv
   do
       echo "Adding component $ser on $SLAVE_NODE "

       curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X POST http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/hosts/$SLAVE_NODE/host_components/$ser

       sleep 2

       echo "Installing service $ser "


       curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"HostRoles": {"state": "INSTALLED"}}'   http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/hosts/$SLAVE_NODE/host_components/$ser
   done

   sleep 6

 ## check if the Components are installed

   new_services=`curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD  -H "X-Requested-By: ambari" -X GET "http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/hosts/${SLAVE_NODE}/host_components" |grep component_name|cut -d: -f 2| sed s/\"//g|sed s/\,//g`

   echo " Services from $SLAVE_NODE : " $new_services

   new_service_cnt=`echo "$new_services"|wc -l`
   service_cnt=`echo "$services"|wc -l`

   echo " Old Serices Available : " $service_cnt
   echo " New Serices installed : " $new_service_cnt



   if [[ $service_cnt == $new_service_cnt ]]
   then
      echo " Services cloned successfully ...  Initiating Start of service ..."
      start_installed_services
   else
      echo " Some of the services not installed Successfully ... Please check the Ambari Console to verify the same... Initing Start of service for installed components..."

      start_installed_services
   fi

}

function add_node {

   echo " **** In Add node function   **** "

   curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X POST http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/hosts/$SLAVE_NODE

   echo " *** Checking to see if the nodes are created **** "

   fin=0
   ret=0

   while [ $fin -ne 1 ]
   do

      chknode1=$(curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X GET http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/hosts/$SLAVE_NODE|grep "\"host_state\" : \"HEALTHY\""|wc -l)

      echo "Checknode : " $chknode1

      if [[ $chknode1 == "1" ]]
      then
         fin=1
      fi

      sleep 10

      let ret=$ret+1

      if [[ $ret == 30 ]]
      then
         echo " Please check the Ambari UI and Agent Logs to see if the node is heart beating to Server and restart the Script... Exiting now... "
         exit 1
       fi

       echo  " Polling for $SLAVE_NODE Addition  - Retries $ret  ***"
   done


   echo " Node has been added successfully (CheckNode Status) : " $chknode1

   add_slave_comps


}


function scale_up {

   echo " **** In scale up  **** "

   checknode=$(curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X GET http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/hosts/$SLAVE_NODE|grep "\"status\" : 404"|wc -l )


   if [[ $checknode == "1" ]]
   then
      echo " The  $SLAVE_NODE dose not exists in the cluster. Preparing to add the $SLAVE_NODE to $CLUSTER_NAME "
      add_node
   else
      echo " $SLAVE_NODE already exists in the cluster $CLUSTER_NAME .. Checking to see if it has the Slave Components installed. If not, Install and Start the same.."
      add_slave_comps
   fi

}

function scale_down {

   echo " **** In scale down  **** "


   echo " **** Initiating Stop on Server: ${SLAVE_NODE}  **** "

   curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"HostRoles": {"state": "INSTALLED"}}'  http://$AMBARI_SERVER:8080/api/v1/clusters/$CLUSTER_NAME/hosts/$SLAVE_NODE/host_components

   sleep 6

   wait "STARTED"

   if [ "$finished" == 0 ]
   then
      echo "Some of the services were not stopped. Please check the Ambari Console to see if there are any issues ... STOP manually and restart script ... "
   else
      echo " All services stopped ... About to delete components "

      delete_comps
   fi

}

##########################################################################################################
################################## START of Main Code ####################################################
##########################################################################################################


if [ "$1" == "SCALEUP" ]; then

   echo "                                      "
   echo "***** About to scale up the Worker Nodes  *****"
   echo "                                      "

   scale_up

elif [ "$1" == "SCALEDOWN" ]; then


   echo "                                      "
   echo "***** About to scale Down the Worker Nodes  *****"
   echo "                                      "

   scale_down

else

   echo "                                                                        "
   echo "                                                                        "
   echo "Usage: ./autoScale.sh [SCALEUP] [SCALEDOWN]                             "
   echo "                                                                        "
   echo "                                                                        "
   exit 1

fi
