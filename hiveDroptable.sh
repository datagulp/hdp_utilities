#!/bin/bash
tables=`hive -e "use dbname;show tables;"`
 
tab_list=`echo "${tables}"`
delete="drop table "
purge=" purge; "
for list in $tab_list
do
    droptable=${droptable}${delete}${list}${purge}
    ##echo "Dropping table ${list} "
    ##hive -e "use dbname; drop table $listi purge;"
done
echo $droptable
 
hive -e "use dbname; ${droptable}"
