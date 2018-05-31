#!/bin/bash 


## Delete Blueprints fir already exists 
##curl -H "X-Requested-By: ambari" -X DELETE  -u admin:admin http://grj-1.field.hortonworks.com:8080/api/v1/blueprints/ansible-hdp

## Input ClusterConfig Json file 
curl -H "X-Requested-By: ambari" -X POST -u admin:admin http://grj-1.field.hortonworks.com:8080/api/v1/blueprints/ansible-hdp -d @./Blueprints/clusterconfig.json

## Provide HDP Repo 
curl -H "X-Requested-By: ambari" -X PUT -u admin:admin http://grj-1.field.hortonworks.com:8080/api/v1/stacks/HDP/versions/2.6/operating_systems/redhat7/repositories/HDP-2.6 -d @./Blueprints/hdprepo.json

## Provide HDP UTILS repo 
curl -H "X-Requested-By: ambari" -X PUT -u admin:admin http://grj-1.field.hortonworks.com:8080/api/v1/stacks/HDP/versions/2.6/operating_systems/redhat7/repositories/HDP-UTILS-1.1.0.22 -d @./Blueprints/hdputilsrepo.json

## Final push - Post the host config
curl -H "X-Requested-By: ambari" -X POST -u admin:admin http://grj-1.field.hortonworks.com:8080/api/v1/clusters/ansible-hdp -d @./Blueprints/hostconfig.json
