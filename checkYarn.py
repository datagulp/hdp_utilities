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
opFile=inpprop["opYARNFile"]
threshold=inpprop["thresholdPercent"]

outfile=open(opFile, 'w')

### Cleanup the output file
outfile.truncate()

print " Curling ", rmserver , ":", rmport

url="http://"+rmserver+":"+rmport+"/ws/v1/cluster/metrics"

res=urllib2.urlopen(url).read()
rmsnap=json.loads(res)

avlMBs=rmsnap["clusterMetrics"]["availableMB"]
allocMBs=rmsnap["clusterMetrics"]["allocatedMB"]
totalMBs=rmsnap["clusterMetrics"]["totalMB"]

print "Available GB     : " + str(float(avlMBs)/1024)
print "Allocated GB     : " + str(float(allocMBs)/1024)
print "Total     GB     : " + str(float(totalMBs)/1024)
print "Threshold %      : " + threshold

used_percent=float(allocMBs)/float(totalMBs)*100

print "Currently Used % : " + str(used_percent)

if float(used_percent) > float(threshold):
    outApps="ALERT:: YARN Usage currently at : " + str(float(used_percent)) + " % exceeding the threshold set at " + threshold + " % "
    outfile.write(outApps)
    outfile.write("\n")

### Closing the file

outfile.close()
