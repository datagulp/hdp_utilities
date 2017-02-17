#!/bin/bash

##########################################################################################################################################
## This script runs the HDFS Rebalancer on the Active name node.
##########################################################################################################################################

## Declarations
thold=20


## Callable Functions

function unSuccessfulEmail {

   echo "ERROR : HDFS Rebalancer Failed. Check Log for more information" |mailx -r hdpadmin@xxxx.com -s "ALERT: HDFS Rebalancer FAILED" user.name@gmail.com
   exit 1

}

## Code begins here

nn1status=`sudo -u hdfs hdfs haadmin  -getServiceState nn1`

nn2status=`sudo -u hdfs hdfs haadmin  -getServiceState nn2`

echo $nn1status
echo $nn2status

if [ "$nn1status" == "active" ]
then
     echo "<<NN Master1>> is the active node. Will Initiate Reblancer "
     ssh -t <<NN Master1>> "sudo -u hdfs hdfs balancer -threshold ${thold}"
else
     if [ "$nn2status" == "active" ]
     then
        echo "<<NN Master2>> is the active node. Will Initiate Reblancer "
        ssh -t <<NN Master2>> " sudo -u hdfs hdfs balancer -threshold ${thold}"
     else
        echo "Both the name nodes are NOT in active state... Check the logs and re-run the script ... Aborting Rebalancer !!! "
        ####unSuccessfulEmail
     fi
fi
