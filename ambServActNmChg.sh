#!/bin/bash

echo " ****** Starting Script to Change Service User names in Ambari ***** "
## To Change Group names , it is a manual process: 
##/var/lib/ambari-server/resouces/scripts/configs.sh -u AmbariUserId -p AmbariPassword set AmbariServer Clustername cluster-env user_group ux_hadoop
##/var/lib/ambari-server/resouces/scripts/configs.sh -u AmbariUserId -p AmbariPassword setAmbariServer Clustername  ranger-env ranger_group ux_ranger

#######################################################################################################
#
#  This script changes the service account user names in ambari using inputs from properties files.  ##
#
#######################################################################################################


. `dirname ${0}`/ambServActNmChg.properties

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

function change_user_name() {

        echo "   "
        echo " Changing Username in progress .....  The New service users will be suffixed with $NEW_SRV_USER_NAME as follows : "
        echo "   "

        while read line
        do

            #####echo $line |sed 's/://g'
            newuservar=`echo $line |awk -F':' '{print $2}'`
            newuser=`echo $line |awk -F':' '{print $3}'|sed 's/"//g'`
            echo $newuservar ":" $newuser$NEW_SRV_USER_NAME

        done < amb_srv_usr_backup.txt

        echo "   "
        echo " Hit ENTER to update the user names ......: "
        echo "   "
        read input

      while read line
        do

            ###echo $line |sed 's/://g'
            envfile=`echo $line |awk -F':' '{print $1}'`
            newuservar=`echo $line |awk -F':' '{print $2}'`
            newuser=`echo $line |awk -F':' '{print $3}'|sed 's/"//g' |xargs`
            nuser=\"$newuser$NEW_SRV_USER_NAME\"
            echo "  Updating $envfile with " $newuservar "---" $nuser

            setuser=`echo "/var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_ADMIN_USERID -p $AMBARI_ADMIN_PASSWORD set  $AMBARI_SERVER ${CLUSTER_NAME} $envfile $newuservar $nuser"`

            eval $setuser

        done < amb_srv_usr_backup.txt

       echo "    "
       echo " Update Completed. Validating new users ... "
       echo "    "

      while read line
        do
            envfile=`echo $line |awk -F':' '{print $1}'`
            /var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_ADMIN_USERID -p $AMBARI_ADMIN_PASSWORD get  $AMBARI_SERVER ${CLUSTER_NAME} $envfile |grep user\"

        done < amb_srv_usr_backup.txt


}



function get_user_name() {

        check_ambari_server

	envs=`curl -u $AMBARI_ADMIN_USERID:$AMBARI_ADMIN_PASSWORD -X GET http://$AMBARI_SERVER:$AMBARI_SERVER_PORT/api/v1/clusters/${CLUSTER_NAME}?fields=Clusters/desired_configs |grep -env |awk -F'"' '{print $2}'`

	envvars=`echo "$envs"`

        cluster_env="cluster-env"

        NEWLINE=$'\n'

        envvars=`echo $envvars ${NEWLINE}  $cluster_env`

        ###   echo $envvars

        rm -f amb_srv_usr_backup.txt



        echo "     "
        echo "     "

        echo " ------------------------------------------------------------------------------------------------ "
        echo " NOTE: Current Ambari User List below: They will be backed up to the file amb_srv_usr_backup.txt  "
        echo " ------------------------------------------------------------------------------------------------ "

	for env in $envvars
	do

	   userlist=`/var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_ADMIN_USERID -p $AMBARI_ADMIN_PASSWORD get  $AMBARI_SERVER ${CLUSTER_NAME} $env |grep user\" |grep ':'`

           ####echo $userlist

            if [ "$userlist" != "" ]; then

 	        ulist=$(echo "$userlist" | sed 's/,//g')

                echo "$ulist"


                printf '%s\n' "$ulist"| while IFS= read ul
                do
                   echo $env ": " $ul >> amb_srv_usr_backup.txt
                done

            fi

	done


        echo "     "
        echo "     "

        echo " Backing up the exiting config for furture Restore amb_srv_usr_backup_$curr_date.txt ... "

        cp amb_srv_usr_backup.txt amb_srv_usr_backup_$curr_date.txt

        response=0

        while [ $response -ne 1 ]
        do
            echo  "    "
            echo  " About to Change the Service account user names ... Response is CASE SENSITIVE YES or NO .... Proceed (YES/NO) ??    "
            echo  "    "
            read resp

            if  ([ $resp == "YES" ] || [ $resp == "NO" ]); then
                echo " Response provided is " $resp
                if [ $resp == "YES" ]; then
                      change_user_name
                else
                      echo " Ambari USer Service account change ABORTED ... "
                fi
                response=1

            else
                echo " Response provided is " $resp
                reponse=0
            fi

        done

}


function restore_change_user_name() {

      echo "   "
      echo " Changing Username in progress ..... : "
      echo "   "

      while read line
      do

            newuservar=`echo $line |awk -F':' '{print $2}'`
            newuser=`echo $line |awk -F':' '{print $3}'|sed 's/"//g'`
            echo $newuservar ":" $newuser

      done < amb_srv_usr_backup_RESTORE.txt

      echo "   "
      echo " Hit ENTER to update the user names ......: "
      echo "   "
      read input

      while read line
        do

            ###echo $line |sed 's/://g'
            envfile=`echo $line |awk -F':' '{print $1}'`
            newuservar=`echo $line |awk -F':' '{print $2}'`
            newuser=`echo $line |awk -F':' '{print $3}'|sed 's/"//g' |xargs`
            nuser=\"$newuser\"
            echo "  Updating $envfile with " $newuservar "---" $nuser

            setuser=`echo "/var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_ADMIN_USERID -p $AMBARI_ADMIN_PASSWORD set  $AMBARI_SERVER ${CLUSTER_NAME} $envfile $newuservar $nuser"`

            eval $setuser

      done < amb_srv_usr_backup_RESTORE.txt

      echo "    "
      echo " Update Completed. Validating new users ... "
      echo "    "

      while read line
      do
            envfile=`echo $line |awk -F':' '{print $1}'`
            /var/lib/ambari-server/resources/scripts/configs.sh -u $AMBARI_ADMIN_USERID -p $AMBARI_ADMIN_PASSWORD get  $AMBARI_SERVER ${CLUSTER_NAME} $envfile |grep user\"

      done < amb_srv_usr_backup_RESTORE.txt

}



function restore_user_name(){

      echo "Make sure the file to be restore is named as amb_srv_usr_backup_RESTORE.txt ... Enter to proceed "
      read input

      restore_change_user_name

}


#### Main code Starts HERE ####


if [ "$1" == "UPDATE" ]; then

   get_user_name

   echo " Deleting residual .json file on the local folder !!! "

   rm -f *.json


elif [ "$1" == "RESTORE" ]; then

   restore_user_name

   echo " Deleting residual .json file on the local folder !!! "

   rm -f *.json

else

   echo "                                                                        "
   echo "                                                                        "
   echo "Usage: ./ambServActNmChg.sh [UPDATE] [RESTORE]                          "
   echo "                                                                        "
   echo "                                                                        "
   exit 1

fi
