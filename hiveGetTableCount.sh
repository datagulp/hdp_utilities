#!/bin/bash

hiveDBName=testdb

tables=`hive -e "use ${hiveDBName};show tables;"`

tab_list=`echo "${tables}"`
select="select count(*) from  "
terminate=";"

for list in $tab_list
do
    selectcnttable=${selectcnttable}${select}${list}${terminate}
done
echo $selectcnttable

hive -e "use ${hiveDBName}; ${selectcnttable}"
