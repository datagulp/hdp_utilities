#!/bin/python
# coding=utf-8

import json
import os
import codecs

### Reading JSON  Ranger Policy Files downloaded from Ranger. The policies needs to be exported into JSON file.
## This code does not use the Request package. It directly calls the curl and Ranger REST API. 


opfile="temp.json"
##tempfile=open(opfile, 'w')

#### curl -iv -u admin:admin -d @ranger_policies.json -H "Content-type:application/json" -X POST  http://RangerAdmin:6080/service/public/api/policy
##url='http://RangerAdmin:6080/service/public/api/policy'
##head = {'Content-type':'application/json'}


policy_file = open('ranger_policies.json', 'r')
policies = json.load(policy_file)
for policy in policies['vXPolicies']:

    print "test =============================="

    ##payld=json.dumps(policy)
    ##ret= requests.post(url, auth=HTTPBasicAuth('admin','admin'), header=head,data=payld)
    ##print ret.status_code

    pols=str(policy).replace("u'", "'")

    print pols
    os.remove(opfile)
    ##tempfile=open(opfile, 'w')
    ##tempfile.write(pols)

    ##with open(opfile, 'w') as tfile:
    with codecs.open(opfile, 'w', 'utf-8') as tfile:
         tfile.write(json.dumps(policy,  indent=4, ensure_ascii=False))



    os.system('curl -iv -u admin:admin -d @temp.json -H "Content-type:application/json" -X POST  http://RangerAdmin:6080/service/public/api/policy')
