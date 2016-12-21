echo "Starting Teragen execution ... "

mapmem=1024
for mtask in 16 32 64 128
do
    hadoop fs -rm -r -skipTrash /tmp/teragen-output
    hadoop jar /usr/hdp/2.4.2.0-258/hadoop-mapreduce/hadoop-mapreduce-examples.jar teragen -Dmapred.map.tasks=$mtask -Dmapreduce.map.memory.mb=$mapmem 1000000000 /tmp/teragen-output
done

echo "Starting Terasort execution ... "
rmem=3096
for rtask in 16 32 64
do
    hadoop fs -rm -r -skipTrash /tmp/terasort-output
    hadoop jar /usr/hdp/2.4.2.0-258/hadoop-mapreduce/hadoop-mapreduce-examples.jar terasort  -Dmapred.reduce.tasks=$rtask -Dmapreduce.reduce.memory.mb=$rmem  /tmp/teragen-output /tmp/terasort-output
done

