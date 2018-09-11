### This python code scans RM output and gets the generates alert if the Job crosses the threshhold. 
### Copyright @ Ganesh Rajagopal

#!/bin/python

import json
import datetime
import calendar
import urllib2
import time
import re
import sys

### Importing Properties JSON

inpprop = json.load(open("runningJobs.properties"))

rmserver=inpprop["rmserver"]
rmport=inpprop["rmport"]
status=inpprop["status"]
threshold=inpprop["longRuuningthresholdHrs"]
exclusionApplicationType=inpprop["exclusionApplicationType"]
exclusionQueue=inpprop["exclusionQueue"]
exclusionID=inpprop["exclusionID"]
opFile=inpprop["opFile"]
opYARNFile=inpprop["opYARNFile"]
thresholdPercent=inpprop["RMthresholdPercent"]


outfile=open(opFile, 'w')
outYARNfile=open(opYARNFile, 'w')

### Cleanup the output file
outfile.truncate()
outYARNfile.truncate()

print " Curling ", rmserver , ":", rmport , " for " , status , " jobs "

url="http://"+rmserver+":"+rmport+"/ws/v1/cluster/apps?state="+status

urlmet="http://"+rmserver+":"+rmport+"/ws/v1/cluster/metrics"

##print url
##url='http://grj-8.field.hortonworks.com:8088/ws/v1/cluster/apps?state=RUNNING'

res=urllib2.urlopen(url).read()
rmsnap=json.loads(res)

##if rmsnap["apps"] and not rmsnap["apps"].isspace():
if rmsnap["apps"]:
    print "***** Found Running Jobs ***** "
else:
    print "***** No Running jobs ***** "
    sys.exit(0)

appls=rmsnap["apps"]["app"]

metres=urllib2.urlopen(urlmet).read()
rmmet=json.loads(metres)

avlMBs=rmmet["clusterMetrics"]["availableMB"]
allocMBs=rmmet["clusterMetrics"]["allocatedMB"]
totalMBs=rmmet["clusterMetrics"]["totalMB"]

print "Available GB     : " + str(float(avlMBs)/1024)
print "Allocated GB     : " + str(float(allocMBs)/1024)
print "Total     GB     : " + str(float(totalMBs)/1024)
print "Threshold %      : " + thresholdPercent + " %"

used_percent=float(allocMBs)/float(totalMBs)*100

print "Currently Used % : " + str(used_percent) + " %"

if float(used_percent) > float(thresholdPercent):
    outYARNApps="ALERT:: YARN Usage currently at : " + str(float(used_percent)) + " % exceeding the threshold set at " + thresholdPercent + " % "
    outYARNfile.write(outYARNApps)
    outYARNfile.write("\n")


dts = datetime.datetime.utcnow().utctimetuple()
currentetime=calendar.timegm(dts)
currentdtime=datetime.datetime.fromtimestamp(currentetime).strftime('%Y-%m-%d %H:%M:%S')

fmt = '%Y-%m-%d %H:%M:%S'
currentdtime=datetime.datetime.fromtimestamp(currentetime).strftime('%Y-%m-%d %H:%M:%S')
curr_dt = datetime.datetime.strptime(currentdtime, fmt)

curr_dt_ts=time.mktime(curr_dt.timetuple())

for appl in appls:
    ##print appl["id"] ,appl["state"] , str(appl["startedTime"])[:10], appl["user"], appl["queue"], appl["applicationType"]

    truncetime=str(appl["startedTime"])[:10]
    jobStartTime=datetime.datetime.fromtimestamp(int(truncetime)).strftime('%Y-%m-%d %H:%M:%S')
    job_run_dt = datetime.datetime.strptime(jobStartTime, fmt)
    job_run_dt_ts=time.mktime(job_run_dt.timetuple())
    ##print (curr_dt - job_run_dt).days
    runhrs=(int(curr_dt_ts - job_run_dt_ts) / 60 ) / 60

    outApps="App Id: " + appl["id"] + " State:  " + appl["state"] + " Hours Running :  " + str(runhrs)  + " Hrs.   User :  " + appl["user"] + " Queue :  " + appl["queue"] +  " Application Type :  " + appl["applicationType"] + "    Running Containers : " + str(appl["runningContainers"]) + " Queue Usage % : " + str(appl["queueUsagePercentage"]) + " Cluster Usage % : " + str(appl["clusterUsagePercentage"]) + " Memory Allocated/Used in MB : " + str(appl["allocatedMB"])


    if float(used_percent) > float(thresholdPercent):
        outYARNfile.write(outApps)
        outYARNfile.write("\n")

    if int(runhrs) > int(threshold):

        if re.search (appl["user"], exclusionID):
           print appl["id"] + " Satisfied UserID execlusion List "
        elif re.search (appl["queue"], exclusionQueue):
           print appl["id"] + " Satisfied Queue  execlusion List "
        elif re.search (appl["applicationType"], exclusionApplicationType):
           print appl["id"] + " Satisfied Application Type  execlusion List "
        else:
           outfile.write(outApps)
           outfile.write("\n")

### Closing the file

outfile.close()
outYARNfile.close()
