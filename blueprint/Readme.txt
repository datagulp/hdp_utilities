Multi-Node Cluster Setup with Optional NN , RM, Hive, Oozie HA integration with Ranger...

Steps for Execution of Blueprint:



curl -H "X-Requested-By: ambari" -X POST -u admin:admin http://localhost:8080/api/v1/blueprints/hdptest -d @clusterconfig.json

curl -H "X-Requested-By: ambari" -X PUT -u admin:admin http://localhost:8080/api/v1/stacks/HDP/versions/2.4/operating_systems/redhat7/repositories/HDP-2.4 -d @hdprepo.json
curl -H "X-Requested-By: ambari" -X PUT -u admin:admin http://localhost:8080/api/v1/stacks/HDP/versions/2.4/operating_systems/redhat7/repositories/HDP-UTILS-1.1.0.20 -d @hdputil.json

curl -H "X-Requested-By: ambari" -X POST -u admin:admin http://localhost:8080/api/v1/clusters/hdptest -d @hostmapping.json
