#!/bin/bash


echo " ****** Executing kinit on other Computes for the ids from property file  ***** "

#######################################################################################################
#
#  This script will Execute periodic Kinit (based on schedule on all compute nodes via pdsh          ##
#
#######################################################################################################


export WCOLL=/home/user/hosts.files

export keytaboutfile="/home/user/keytabout.txt"
export hostfile="/home/user/uat.hosts"
export usersfile="/home/user/scripts/autoKinit.users"

rm -rf /home/user/scripts/keytabout.txt


while read line
do
   IFS=':' read -a user <<< "${line}"
   echo "${user[0]}"
   echo "${user[1]}"
   pdsh "sudo klist -kt /etc/security/keytabs/${user[1]}.headless.keytab"
   pdsh "sudo -u ${user[0]} /usr/bin/kinit -kt /etc/security/keytabs/${user[1]}.headless.keytab ${user[0]}@REALM.COM"
   pdsh "ls -lart  /tmp/krb5cc* |grep -w ${user[0]}" >> $keytaboutfile

done < $usersfile


## Compare output to make sure the response is received from all the servers.

keyout=`cat $keytaboutfile | awk '{print $1}' | sort -u | sed 's/:/''/g'`
hosts=`cat $hostfile | sort -u | sed 's/' '/''/g'`



echo "Hosts from keyout file"
echo $keyout
echo " Starting Compare ************ "
echo "Hosts from host file"
echo $hosts

echo " Starting Compare ************ "

if [[ "$keyout" == "$hosts" ]]
   then
      echo " Received response from all the hosts. Validating Keytab time ... "
      kdate=` cat $keytaboutfiles | awk '{print $7 " " $8 " " $9}' | sort -u`
      keydate=`date -d "$kdate"`

      cdate=`date`

      ddiff=`date -d @$(( $(date -d "$cdate" +%s) - $(date -d "$keydate" +%s) )) -u +'%H:%M:%S'`

      ##echo $ddiff


      IFS=':' read -a mins <<< "${ddiff}"

      ## echo "${mins[0]}"
      ## echo "${mins[1]}"

      if [[ ${mins[0]} -ge 0 && ${mins[1]} -ge 5 ]]
      then

         echo " Validate the krb5cc files on the keytabout file. Timestamp greater than 5 mins "
         exit 1
      else
         echo " Timestamp on the krb5cc files  well with in limits ... "
         echo " ********   Kinit completed Successfully ************** "

      fi


   else
      echo " Unable to get the response from all the hosts ... "
      exit 1
fi
