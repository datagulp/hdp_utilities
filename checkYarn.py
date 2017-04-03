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

print "Available MB : " + str(avlMBs)
print "Allocated MB : " + str(allocMBs)
print "Total     MB : " + str(totalMBs)

used_percent=float(allocMBs)/float(totalMBs)*100

print "Used Percent : " + str(used_percent)

if float(used_percent) > float(threshold):
    outApps="ALERT:: YARN Usage currently at : " + str(float(used_percent)) + " % exceeding the threshold set at " + threshold + " % "
    outfile.write(outApps)
    outfile.write("\n")

### Closing the file

outfile.close()
