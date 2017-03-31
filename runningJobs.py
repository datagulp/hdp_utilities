#!/bin/python

import json
import datetime
import calendar
import urllib2
import time
import re

### Importing Properties JSON


inpprop = json.load(open("runningJobs.properties"))

rmserver=inpprop["rmserver"]
rmport=inpprop["rmport"]
status=inpprop["status"]
threshold=inpprop["threshold"]
exclusionApplicationType=inpprop["exclusionApplicationType"]
exclusionQueue=inpprop["exclusionQueue"]
exclusionID=inpprop["exclusionID"]
opFile=inpprop["opFile"]

outfile=open(opFile, 'w')

### Cleanup the output file
outfile.truncate()

print " Curling ", rmserver , ":", rmport , " for " , status , " jobs "

url="http://"+rmserver+":"+rmport+"/ws/v1/cluster/apps?state="+status

##print url
##url='http://grj-8.field.hortonworks.com:8088/ws/v1/cluster/apps?state=RUNNING'

res=urllib2.urlopen(url).read()
rmsnap=json.loads(res)
appls=rmsnap["apps"]["app"]

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

    ignoreFlag=0
    if int(runhrs) > int(threshold):

        if re.search (appl["user"], exclusionID):
           print appl["id"] + " Satisfied UserID execlusion List "
        elif re.search (appl["queue"], exclusionQueue):
           print appl["id"] + " Satisfied Queue  execlusion List "
        elif re.search (appl["applicationType"], exclusionApplicationType):
           print appl["id"] + " Satisfied Application Type  execlusion List "
        else:
           outApps="App Id: " + appl["id"] + " State:  " + appl["state"] + " Hours Running :  " + str(runhrs)  + " Hrs.   User :  " + appl["user"] + " Queue :  " + appl["queue"] +  " Application Type :  " + appl["applicationType"]
           outfile.write(outApps)
           outfile.write("\n")

### Closing the file

outfile.close()
