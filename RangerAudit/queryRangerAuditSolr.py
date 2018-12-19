#!/bin/python
#####################################################################################
## This program will read the input JSON properties files and query Ranger Audit Solr Collection
## Author : Ganesh Rajagopal
## PreReq : 
##    1. Access to Solr Ranger Audit Collection to run the Queries 
##    2. Updated queryRangerAuditsolr.properties
####################################################################################   



import os
import json
import urllib2
import urllib
import sys
import array as arr
import commands
from datetime import datetime


##
## Execute Final Query and Store the output as CSV file
##


def executeFinalQuery(finalUrl, totalNum):


   outFile = "SolrAudit_Output_" +  str(datetime.now().strftime("%Y%m%d_%H%M%S")) + ".csv"
   finalUrl = finalUrl + "&wt=csv&rows=" + totalNum + "\""
   status, output = commands.getstatusoutput(finalUrl)

   if status == 0:
      queryOutFile = open(outFile, 'w')
      print "Downloading Output to " + outFile
      queryOutFile.write(output)
      queryOutFile.close()
      print "Download Complete to current directory. Please export the file " + outFile + " and open using Microsoft Excel "

   else:
      raise Exception (" Curl Failed to get output  " )



##
## Parse Properties file And Construct Solr Query for Submission
##


def readnConstructQuery():
    print "Read the properties files and Construct the Query  "

    inputProp = json.load(open("queryRangerAuditsolr.properties"))


    solrurl = inputProp["solrURL"]
    solrport = inputProp["solrPort"]
    solrCollection = inputProp["solrCollection"]
    solrShards = inputProp["solrShards"]
    kerberosEnabled = inputProp["kerberosEnabled"]

    access = inputProp["access"]
    cliIP = inputProp["cliIP"]
    cluster = inputProp["cluster"]
    repo = inputProp["repo"]
    reqUser = inputProp["reqUser"]
    resource = inputProp["resource"]
    fromTime = inputProp["timeFrom"]
    toTime = inputProp["timeTo"]
    freeFormQuery = inputProp["freeFormQuery"]


    curlPart  = "curl -g  -sS"
    negotiate = "  --negotiate  -u : "
    httpPart  = "\"http://"

    if kerberosEnabled.upper() == "Y":
        buildCurl = curlPart + negotiate + httpPart
    else:
        buildCurl = curlPart + httpPart


    appendUrl = ""

    ########################################
    ## DO NOT CHANGE THE FOLLOWING ORDER
    ########################################

    if solrurl.strip()  == "":
       raise Exception ("Solr URL is Empty ")
    else:
       appendUrl = buildCurl + solrurl.strip()


    if solrport.strip()  == "":
       raise Exception (" Solr Port is Empty " )
    else:
       appendUrl = appendUrl + ":" + solrport.strip()+"/solr/"

    if solrShards.strip()  == "":
       raise Exception (" Solr Shard  is Empty " )
    else:
       appendUrl = appendUrl +  solrShards.strip() + "/select?"

    if solrCollection.strip()  == "":
       raise Exception (" Solr Collection is Empty " )
    else:
       appendUrl = appendUrl +  "collection=" +  solrCollection.strip() + "&q="


    ## Check to and From Timestamp
    if fromTime.strip()  == "" or toTime.strip()  == "":
       raise Exception (" From and To Time are required filters. " )
    else:
       accEvntTime = "evtTime: [" + fromTime + " TO " + toTime + "]"
       #print accEvntTime


    ## Append User names to the Query
    if len(reqUser) > 0:
       accUser = "reqUser : ("
       for i, users in enumerate(reqUser, start=1):
          accUser = accUser + users
          if i != len(reqUser):
             accUser = accUser + " OR "
       accUser = accUser + ") AND "
    else:
       accUser = ""

    if cluster.strip()  == "":
       raise Exception (" Cluster is Empty ")

    ## Append repos to the Query
    if len(repo) > 0:
       accRepo =  "("
       for i, repos in enumerate(repo, start=1):
          cluster_repo =  cluster + "_" + repos
          accRepo = accRepo + "(repo: " + cluster_repo

          ## Append Resources to the existing query
          if len(resource) > 0:
             if  repos in resource:
                res = resource[repos]
                if len(res) > 0:
                   accRes = "("
                   for j, r in enumerate(res, start=1):
                      if repos == "hadoop":
                         r = r.replace('/','\/') ## Escape the path if the resource is hadoop

                      accRes = accRes +  "resource: " + r
                      if j != len(res):
                         accRes = accRes + " OR "
                   accRes = accRes + ")"
                   accRepo = accRepo + " AND " + accRes

          ## Append Access controls to the Existing Queries if exists
          if len(access) > 0:
             if  repos in access:
                acc = access[repos]
                if len(acc) > 0:
                   accAcc = "("
                   for k, ac in enumerate(acc, start=1):
                      accAcc = accAcc +  "access: " + ac
                      if k != len(acc):
                         accAcc = accAcc + " OR "
                   accAcc = accAcc + ")"
                   ##print accAcc
                   accRepo = accRepo + " AND " + accAcc


          accRepo =  accRepo + ")"
          if i != len(repo):
              accRepo = accRepo + " OR "
       accRepo = accRepo + ") AND "
       #print accRepo
    else:
       accRepo = ""

    ## Append Ip Address Filter to the list if present
    if len(cliIP) > 0:
       accIP = "cliIP : ("
       for i, IP in enumerate(cliIP, start=1):
          accIP = accIP + IP
          if i != len(cliIP):
             accIP = accIP + " OR "
       accIP = accIP + ") AND "
    else:
       accIP = ""


    queryString = ""

    if accUser != "" :
       queryString = queryString + accUser

    if accRepo != "" :
       queryString = queryString +  accRepo

    if accIP != "" :
       queryString = queryString +  accIP

    queryString = queryString +  accEvntTime

    #queryString = accUser + accRepo + accIP + accEvntTime


    print "   "
    if freeFormQuery.strip() != "":
       print " ***  Free Form Query Entered. All other properties ignored *** "
       queryString = freeFormQuery.strip()
       print "==========FreeForm  Solr Query below for reference=================="
    else:
       print "==========Dynamic Solr Query Built below for reference=============="

    print "   "
    print queryString
    print "   "
    print "===================================================================="

    queryString = queryString.replace(' ', '%20').replace('(','%28').replace(')', '%29')

    finalUrl = appendUrl + queryString

    getcountUrl = appendUrl + queryString + "&wt=json&indent=true\""

    status, output = commands.getstatusoutput(getcountUrl)

    if status == 0:
       curlOut = json.loads(output)
       totalNum =  curlOut["response"]["numFound"]
       print "Total number of records to be  extracted : " + str(totalNum)
       print "Preparing and Executing Final Query to download CSV file "

       executeFinalQuery(finalUrl, str(totalNum))

    else:
       raise Exception (" Curl Failed to get output  " )


###
### Main Function
###

def main():
    os.system('cls' if os.name == 'nt' else 'clear')
    readnConstructQuery()

if __name__ == "__main__":
    main()
