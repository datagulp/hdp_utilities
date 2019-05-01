# Databricks notebook source
# MAGIC %md
# MAGIC # Databricks Overview 
# MAGIC 
# MAGIC Databricks provides a Unified Analytics Platform to help business transform their data strategy. We do this by providing a collaborative, scalable, and easy-to-use environment built around Databricks Runtime and Apache Spark.
# MAGIC 
# MAGIC Databricks provides several key differentiators that will be shown in this demo, including Data engineering capabilities, Databricks Delta,  Databricks Runtime.
# MAGIC 
# MAGIC In this demo, we'll cover the basics of Databricks using the following architecture:
# MAGIC <div style="text-align: center; line-height: 0; padding-top: 0px;"><br><img src="https://i.imgur.com/5n2ZX8o.png" height="00" width="700"></div>
# MAGIC 
# MAGIC We'll break this down into 4 sections:
# MAGIC - Platform Overview
# MAGIC - Loading and viewing data
# MAGIC - Manipulating and enriching data
# MAGIC - Streaming data
# MAGIC - Databricks Delta

# COMMAND ----------

# MAGIC %run ./Delta-Setup

# COMMAND ----------

# MAGIC %fs ls /databricks/ganeshrj/stocks

# COMMAND ----------

# DBTITLE 1,Extract Metadata Information from MySQL Database
 stocksDF = spark.read.jdbc(url=jdbcUrl, table="metadata", properties=connectionProps)
 display (stocksDF)

# COMMAND ----------

# MAGIC %md
# MAGIC Run the following code cell to set up paths and remove any leftover data.

# COMMAND ----------

# DBTITLE 1,Setup Paths for Data Files
genericDataPath = userhome + "/generic/stock-data/"
deltaDataPath = userhome + "/delta/stock-data/"
backfillDataPath = userhome + "/delta/backfill-data/"
deltaMiniDataPath = userhome + "/delta/mini-delta"

dbutils.fs.rm(genericDataPath, True)
dbutils.fs.rm(deltaDataPath, True)
dbutils.fs.rm(backfillDataPath, True)
dbutils.fs.rm(deltaMiniDataPath, True)

# COMMAND ----------

# MAGIC %md
# MAGIC 
# MAGIC ###  READ csv data for each stock then WRITE to Parquet / Delta
# MAGIC 
# MAGIC Read the data into a DataFrame. Since this is a CSV file, let Spark infer the schema from the first row by setting
# MAGIC * `inferSchema` to `true`
# MAGIC * `header` to `true`
# MAGIC 
# MAGIC Drop the `Adj Close` column, as it's not needed.
# MAGIC 
# MAGIC  

# COMMAND ----------

# MAGIC %md
# MAGIC ## Part 2: Loading and viewing data
# MAGIC 
# MAGIC Now that we've seen the environment, we can load some data. In this case, we'll load user data from a MySQL database, and also some reference data from a CSV file on S3.
# MAGIC <div style="text-align: center; line-height: 0; padding-top: 9px;"><img src="https://i.imgur.com/r4hY0rS.png" height="00" width="700"></div>
# MAGIC 
# MAGIC On Databricks, it's simple to unify many different sources across traditional silos into a single environment; it's just a few lines of code.

# COMMAND ----------

# DBTITLE 1,Read the data from CSV, Enrich data by adding month, year and the appropriate Stock Tickers
for stickers in ['APPL', 'GOOG', 'AMZN', 'NFLX']:
  path = "dbfs:/databricks/ganeshrj/stocks/" + stickers + ".csv"
  print (path)  
  rawDataDF = (spark.read 
  .option("inferSchema", "true") 
  .option("header", "true")
  .csv(path)
  .drop("Adj Close"))
  
  rawDataDF = rawDataDF.withColumn("month",(month(rawDataDF.date))).withColumn("Year",(year(rawDataDF.date))).withColumn("Stickers", lit(stickers))
  
  ## Join with StocksDF to get the company name
  joinedDF=rawDataDF.join(broadcast(stocksDF), rawDataDF.Stickers == stocksDF.sticker).drop("Stickers")
  
  ### Write as Parquet 
  joinedDF.write.format("parquet").partitionBy("Year").mode("append").save(genericDataPath)
  
  ### Write as Delta
  joinedDF.write.format("delta").partitionBy("Year").mode("append").save(deltaDataPath)
  
  display (joinedDF)
  
   

# COMMAND ----------

rawDataDF.printSchema()

# COMMAND ----------

# MAGIC %md-sandbox
# MAGIC ### CREATE Using Non-Delta Pipeline
# MAGIC 
# MAGIC Create a table called `generic_stocks` using `parquet` out of the above data.
# MAGIC 
# MAGIC <img alt="Caution" title="Caution" style="vertical-align: text-bottom; position: relative; height:1.3em; top:0.0em" src="https://files.training.databricks.com/static/images/icon-warning.svg"/> Notice how you MUST specify a schema and partitioning info!

# COMMAND ----------

spark.sql("""
    use ngcdemo
  """)
spark.sql("""
    DROP TABLE IF EXISTS generic_stocks
  """)
spark.sql("""
    CREATE TABLE generic_stocks (
      Date TIMESTAMP,
      Open DOUBLE,
      High DOUBLE,
      Low DOUBLE,
      Close DOUBLE,
      Volume INTEGER,
      Month INTEGER,
      Year INTEGER, 
      Sticker STRING,
      name STRING)
    USING parquet 
    OPTIONS (path = '{}' )
    PARTITIONED BY (Year)
  """.format(genericDataPath))
None

# COMMAND ----------

# MAGIC %md
# MAGIC Perform a simple `count` query to verify the number of records.

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT count(*) FROM generic_stocks

# COMMAND ----------

# MAGIC %md-sandbox
# MAGIC 
# MAGIC <img alt="Caution" title="Caution" style="vertical-align: text-bottom; position: relative; height:1.3em; top:0.0em" src="https://files.training.databricks.com/static/images/icon-warning.svg"/> Wait, no results? 
# MAGIC 
# MAGIC What is going on here is a problem that stems from its Apache Hive origins.
# MAGIC It's the concept of <br>
# MAGIC <b>schema on read</b> where data is applied to a plan or schema as it is pulled out of a stored location, rather than as it goes into a stored location.
# MAGIC 
# MAGIC This means that as soon as you put data into a data lake, the schema is unknown <i>until</i> you perform a read operation.
# MAGIC 
# MAGIC To remedy, you repair the table using `MSCK REPAIR TABLE`.
# MAGIC 
# MAGIC <img alt="Side Note" title="Side Note" style="vertical-align: text-bottom; position: relative; height:1.75em; top:0.05em; transform:rotate(15deg)" src="https://files.training.databricks.com/static/images/icon-note.webp"/> Only after table repair is our count of customer data correct.

# COMMAND ----------

# MAGIC %sql
# MAGIC MSCK REPAIR TABLE generic_stocks;
# MAGIC 
# MAGIC SELECT  Sticker , High, Low  FROM generic_stocks where date(Date) = '2019-03-25' 

# COMMAND ----------

# MAGIC %sql 
# MAGIC 
# MAGIC select * from generic_stocks;

# COMMAND ----------

# MAGIC %sql 
# MAGIC 
# MAGIC select * from stocks_delta;

# COMMAND ----------

# MAGIC %md
# MAGIC ## Part 3: Manipulating and Enriching Data
# MAGIC 
# MAGIC We've loaded some data into Databricks, but now what? Databricks makes it easy to clean, manipulate, enrich, and then store data for downstream use. 
# MAGIC 
# MAGIC We'll blend our two data sources together, then view the results. We'll also use __Delta__ to persist the data into a permanent, performant, and easily accessible format.
# MAGIC 
# MAGIC <div style="text-align: center; line-height: 0; padding-top: 9px;"><img src="https://i.imgur.com/N2ASM7K.png" height="00" width="700"></div>

# COMMAND ----------

# DBTITLE 1,Read APPL Sentiment Data  from HDFS
from pyspark.sql.types import * 


sentimentsDF = spark.read.option("inferSchema", "true").option("header", "true").csv("hdfs://hdp-c1.ganeshrj.com:8020/user/root/APPL_Sentiments.csv")


redinedDF=sentimentsDF.withColumnRenamed("published at", "publishTime")

redinedDF.write.format("delta").saveAsTable("ngcdemo.appl_sentiments")


# COMMAND ----------

# MAGIC %sql describe ngcdemo.appl_sentiments 

# COMMAND ----------

# MAGIC %sql 
# MAGIC select count(title) as cnt, date(publishTime) as pdate, avg(sentiment) as senti from ngcdemo.appl_sentiments group by date(publishTime) order by count(title) desc;

# COMMAND ----------

# MAGIC %sql 
# MAGIC 
# MAGIC select ticker ,title, date(publishTime), sentiment from ngcdemo.appl_sentiments where date(publishTime) = '2019-03-25'

# COMMAND ----------

# MAGIC %sql 
# MAGIC 
# MAGIC select    Sticker ,Open, High, Low, Close, Volume, temp.senti as avg_sentiment  FROM generic_stocks , 
# MAGIC (select count(title) as cnt, date(publishTime) as pdate, avg(sentiment) as senti from ngcdemo.appl_sentiments group by date(publishTime) order by count(title) desc limit 1) temp 
# MAGIC where date(Date) = temp.pdate and Sticker = 'APPL';

# COMMAND ----------

# MAGIC %md
# MAGIC   
# MAGIC ## DELTA
# MAGIC 
# MAGIC Create a table called `stocks_delta` using `DELTA` out of the above data.

# COMMAND ----------


spark.sql("""
  USE ngcdemo
""")

spark.sql("""
  DROP TABLE IF EXISTS stocks_delta
""")
spark.sql("""
  CREATE TABLE stocks_delta
  USING DELTA 
  LOCATION '{}' 
""".format(deltaDataPath))
None

# COMMAND ----------

# MAGIC %md
# MAGIC 
# MAGIC #### Metadata
# MAGIC 
# MAGIC Since we already have data backing `stocks_delta` in place, 
# MAGIC the table in the Hive metastore automatically inherits the schema, partitioning, 
# MAGIC and table properties of the existing data. 
# MAGIC 
# MAGIC Note that we only store table name, path, database info in Hive metastore,
# MAGIC the actual schema is stored in `_delta_logs`.
# MAGIC 
# MAGIC Metadata is displayed through `DESCRIBE DETAIL <tableName>`.
# MAGIC 
# MAGIC As long as we have some data in place already for a Delta table, we can infer schema.

# COMMAND ----------

# MAGIC %sql
# MAGIC DESCRIBE  stocks_delta

# COMMAND ----------

# MAGIC %md-sandbox
# MAGIC Perform a simple `count` query to verify the number of records.
# MAGIC 
# MAGIC <img alt="Caution" title="Caution" style="vertical-align: text-bottom; position: relative; height:1.3em; top:0.0em" src="https://files.training.databricks.com/static/images/icon-warning.svg"/> Notice how the count is right off the bat; no need to worry about table repairs.

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT count(*) FROM generic_stocks

# COMMAND ----------

# MAGIC %md
# MAGIC ## Append
# MAGIC 
# MAGIC Now - Let's append some NetFlix Stock Data 

# COMMAND ----------

janDataDF = (spark       
  .read                                              # Read a DataFrame from storage
  .option("inferSchema","true")                      # Infer schema
  .option("header","true")                           # File has a header
  .csv("dbfs:/databricks/ganeshrj/apple/NFLX_JAN.csv")     # Path to file 
  .drop("Adj Close"))

janDataDF = janDataDF.withColumn("Month", month(janDataDF.Date)).withColumn("Year",(year(janDataDF.Date))).withColumn("Stickers", lit("NFLX")) 

display(janDataDF)

# COMMAND ----------

# MAGIC %md
# MAGIC Do a simple count of number of new items to be added to production data.

# COMMAND ----------

janDataDF.count()

# COMMAND ----------

# MAGIC %md
# MAGIC ## APPEND Using Non-Delta pipeline
# MAGIC Append to the production table.
# MAGIC 
# MAGIC In the next cell, load the new data in `parquet` format and save to `../generic/aapl-data/`.

# COMMAND ----------

(janDataDF
  .write
  .format("parquet")
  .partitionBy("Year")
  .mode("append")
  .save(genericDataPath)
)

# COMMAND ----------

# MAGIC %md
# MAGIC 
# MAGIC Query should show new results.
# MAGIC 
# MAGIC Should be `5503 + 21 = 5524` rows

# COMMAND ----------

# MAGIC %sql
# MAGIC 
# MAGIC select count(*) from generic_stocks

# COMMAND ----------

# MAGIC %md-sandbox
# MAGIC 
# MAGIC That's the not the right count (the new rows haven't been added in correctly). 
# MAGIC 
# MAGIC <img alt="Caution" title="Caution" style="vertical-align: text-bottom; position: relative; height:1.3em; top:0.0em" src="https://files.training.databricks.com/static/images/icon-warning.svg"/> Repair the table again and count the number of records.

# COMMAND ----------

# MAGIC %sql
# MAGIC MSCK REPAIR TABLE generic_stocks;
# MAGIC 
# MAGIC SELECT count(*) FROM generic_stocks

# COMMAND ----------

# MAGIC %md
# MAGIC ## APPEND Using Delta Pipeline
# MAGIC 
# MAGIC Next, repeat the process by writing to Delta format. 
# MAGIC 
# MAGIC In the next cell, load the new data in Delta format and save to `/delta/aapl-data/`.

# COMMAND ----------

# MAGIC %sql 
# MAGIC 
# MAGIC describe stocks_delta;

# COMMAND ----------

(janDataDF
  .write
  .format("delta")
  .partitionBy("Year")
  .mode("append")
  .save(deltaDataPath)
)

# COMMAND ----------

janDataDF = (spark       
  .read                                              # Read a DataFrame from storage
  .option("inferSchema","true")                      # Infer schema
  .option("header","true")                           # File has a header
  .csv("dbfs:/databricks/ganeshrj/apple/NFLX_JAN.csv")     # Path to file 
  .drop("Adj Close"))

janDataDF = janDataDF.withColumn("Month", month(janDataDF.Date)).withColumn("Year",(year(janDataDF.Date))).withColumn("sticker1", lit("NFLX")) 

## Join with StocksDF to get the company name
janDataDF=janDataDF.join(broadcast(stocksDF), janDataDF.sticker1 == stocksDF.sticker).drop("sticker1") 

display(janDataDF)

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT count(*) FROM stocks_delta

# COMMAND ----------

# MAGIC %md
# MAGIC 
# MAGIC ## UPSERT 

# COMMAND ----------

# MAGIC %md
# MAGIC 
# MAGIC ## UPSERT Using Non-Delta Pipeline 
# MAGIC 
# MAGIC This feature is not supported in non-Delta pipelines.
# MAGIC 
# MAGIC Furthermore, no updates or deletes, or any sort of modifications are supported in non-Delta pipelines.

# COMMAND ----------

# MAGIC %md
# MAGIC ## UPSERT Using Delta Pipeline

# COMMAND ----------

# MAGIC %md
# MAGIC ## Part 4: Update and Insert Data
# MAGIC 
# MAGIC **Databricks Delta** delivers a powerful transactional storage layer by harnessing the power of Apache Spark and Databricks DBFS. The core abstraction of Databricks Delta is an optimized Spark table that stores data as Parquet files in DBFS.
# MAGIC 
# MAGIC Maintains a transaction log that efficiently tracks changes to the table.
# MAGIC 
# MAGIC You read and write data stored in the delta format using the same familiar Apache Spark SQL batch and streaming APIs that you use to work with Hive tables and DBFS directories. With the addition of the transaction log and other enhancements, Databricks Delta offers significant benefits:
# MAGIC 
# MAGIC #### ACID transactions
# MAGIC Multiple writers can simultaneously modify a dataset and see consistent views. For qualifications, see Multi-cluster writes.
# MAGIC Writers can modify a dataset without interfering with jobs reading the dataset.
# MAGIC #### Fast read access
# MAGIC Automatic file management organizes data into large files that can be read efficiently.
# MAGIC Statistics enable speeding up reads by 10-100x and and data skipping avoids reading irrelevant information.
# MAGIC 
# MAGIC #### Upserts (MERGE INTO)
# MAGIC The MERGE INTO statement allows you to merge a set of updates and insertions into an existing dataset.

# COMMAND ----------

dbutils.fs.rm(deltaMiniDataPath, True)
deltaMiniDataPath = userhome + "/delta/mini-delta1"
newJanDataDF = janDataDF.where((col("Date") < '2018-01-13T00:00:00.000+0000')   &  (col("sticker") == 'NFLX'))

(newJanDataDF
  .write
  .format("delta")
  .partitionBy("Year")
  .save(deltaMiniDataPath) 
)

display (newJanDataDF)
spark.sql("use ngcdemo")
spark.sql("""
    DROP TABLE IF EXISTS jan_nflx_delta_mini
  """)
spark.sql("""
    CREATE TABLE jan_nflx_delta_mini
    USING DELTA 
    LOCATION '{}' 
  """.format(deltaMiniDataPath))
None

# COMMAND ----------

# MAGIC %md 
# MAGIC ## Fix the data issue 

# COMMAND ----------

from pyspark.sql.functions import lit
correctedDataDF = (newJanDataDF
  .withColumn("Volume", lit(4000000))
 )

spark.sql("use ngcdemo")
spark.sql("DROP TABLE IF EXISTS corrected_nflx_delta_to_upsert")
correctedDataDF.write.saveAsTable("corrected_nflx_delta_to_upsert")

# COMMAND ----------

# MAGIC %sql select * from corrected_nflx_delta_to_upsert

# COMMAND ----------

# MAGIC %sql
# MAGIC MERGE INTO stocks_delta
# MAGIC USING corrected_nflx_delta_to_upsert
# MAGIC ON corrected_nflx_delta_to_upsert.Date = stocks_delta.Date
# MAGIC WHEN MATCHED THEN
# MAGIC   UPDATE SET
# MAGIC     stocks_delta.Volume = corrected_nflx_delta_to_upsert.Volume
# MAGIC WHEN NOT MATCHED
# MAGIC   THEN INSERT (Date, Open, High, Low, Close, Volume, Month, Year, sticker, name)
# MAGIC   VALUES (
# MAGIC     corrected_nflx_delta_to_upsert.Date,
# MAGIC     corrected_nflx_delta_to_upsert.Open,
# MAGIC     corrected_nflx_delta_to_upsert.High,
# MAGIC     corrected_nflx_delta_to_upsert.Low,
# MAGIC     corrected_nflx_delta_to_upsert.Close,
# MAGIC     corrected_nflx_delta_to_upsert.Volume,
# MAGIC     corrected_nflx_delta_to_upsert.Month,
# MAGIC     corrected_nflx_delta_to_upsert.Year,
# MAGIC     corrected_nflx_delta_to_upsert.sticker,
# MAGIC     corrected_nflx_delta_to_upsert.name)

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT * FROM stocks_delta
# MAGIC where Date < '2018-01-13T00:00:00.000+0000' and sticker = 'NFLX'

# COMMAND ----------

# MAGIC %md
# MAGIC 
# MAGIC ## Timetravel

# COMMAND ----------

# MAGIC %sql 
# MAGIC 
# MAGIC describe history stocks_delta;

# COMMAND ----------

# MAGIC %sql 
# MAGIC 
# MAGIC SELECT count(*) FROM stocks_delta VERSION AS OF 1 where volume = 4000000;

# COMMAND ----------

# MAGIC %sql 
# MAGIC 
# MAGIC SELECT count(*) FROM stocks_delta VERSION AS OF  where volume = 4000000;

# COMMAND ----------

# MAGIC %sql 
# MAGIC 
# MAGIC select count(*) from stocks_delta   TIMESTAMP AS OF "2019-04-12 13:53:01"    where volume = 4000000;

# COMMAND ----------

# MAGIC %sql 
# MAGIC 
# MAGIC Optimize stocks_delta  
# MAGIC    zorder by Date

# COMMAND ----------

# MAGIC %sql
# MAGIC SELECT * FROM stocks_delta
# MAGIC where Date < '2018-01-13T00:00:00.000+0000' and sticker = 'NFLX'

# COMMAND ----------

# MAGIC %md
# MAGIC ## Part 5: Streaming Data - combine live and historical data (without the complexity of traditional lambda architecture)
# MAGIC 
# MAGIC In Databricks, incorporating real-time or near-real-time data is just as simple as incorporating static data. Let's look at how we can combine a streaming source, in this case eProcessing Events, with our existing data, using the power of Delta and Databricks Runtime.
# MAGIC 
# MAGIC <div style="text-align: center; line-height: 0; padding-top: 9px;"><br><img src="https://i.imgur.com/RYOs8lB.png" height="00" width="700"></div>

# COMMAND ----------

streamingDataPath = userhome + "/delta/streaming/"
eventStreamPath = userhome + "/delta/eventStream"
dbutils.fs.rm(streamingDataPath, True)

# COMMAND ----------

from datetime import datetime
def createEvents( count, date, eventType, open1, high, low, close, month, year, sticker, name ):
  return [(datetime.strptime(date, '%Y-%m-%d'), eventType, open1, high, low, close, month, year, sticker, name , ((i%5)+1) * count ) for i in range(count)]

# COMMAND ----------

from pyspark.sql.types import *
schemaFields = [StructField('date', DateType(), True), 
                StructField('eventType', StringType(), True), 
                StructField('open1', DoubleType(), True), 
                StructField('high', DoubleType(), True), 
                StructField('low', DoubleType(), True), 
                StructField('close', DoubleType(), True),
                StructField('month', IntegerType(), True), 
                StructField('year', IntegerType(), True),
                StructField('sticker', StringType(), True), 
                StructField('name', StringType(), True),               
                StructField('volume', IntegerType(), True)]
schema = StructType(schemaFields)

# COMMAND ----------

# MAGIC %md 
# MAGIC ## Simulate a Batch Insert 

# COMMAND ----------

insertDataDF = spark.createDataFrame(createEvents( 1000, "2017-10-01", "batch-insert", 123.33, 128.33, 121.40, 124.33, 10, 2017, 'NFLX', 'Netflix Inc'), schema)
insertDataDF.write.format("delta").save(streamingDataPath)


# COMMAND ----------

display (insertDataDF)

# COMMAND ----------

# MAGIC %md 
# MAGIC ## Simulate a Batch Append for couple of Stocks  

# COMMAND ----------

(spark.createDataFrame(createEvents(5000, "2017-10-02", "batch-append-1", 123.33, 128.33, 121.40, 124.33, 10, 2017, 'APPL', 'Apple Computers Inc'), schema)
  .write
  .format("delta")
  .mode("append")
  .save(str(streamingDataPath)))

# COMMAND ----------

(spark.createDataFrame(createEvents(5000, "2017-10-03", "batch-append-2", 123.33, 128.33, 121.40, 124.33, 10, 2017, 'GOOG', 'Google Inc'), schema)
  .write
  .format("delta")
  .mode("append")
  .save(str(streamingDataPath)))

# COMMAND ----------

# MAGIC %md 
# MAGIC ## Display the results  

# COMMAND ----------

display(
  (spark
  .readStream
  .format("delta")
  .load(str(streamingDataPath))
  .groupBy("date","eventType", "sticker")
  .count()
  .orderBy("date"))
)

# COMMAND ----------

# MAGIC %md 
# MAGIC ## Kick the streaming job and watch the data being processed

# COMMAND ----------

df = spark.createDataFrame(createEvents(10000, "2017-10-10", "stream", 123.33, 128.33, 121.40, 124.33, 10, 2017, 'NFLX', 'Netflix Inc'), schema)
schemaNew = df.schema
(df.write
  .format("json")
  .mode("overwrite")
  .save(str(eventStreamPath)))

streamDF = spark.readStream.schema(schemaNew).option("maxFilesPerTrigger", 1).json(str(eventStreamPath))

(streamDF
  .writeStream
  .format("delta")
  .option("path", streamingDataPath)
  .option("checkpointLocation", "/tmp/checkpoint/")
  .start())

# COMMAND ----------

# MAGIC %md
# MAGIC ## Summary:  
# MAGIC 
# MAGIC Databricks provides a transformative, best-in-class platform that unifies Data Science, Analytics, and Data Engineering to help solve the toughest business problems in the world.
# MAGIC 
# MAGIC In a few lines of code, we created a cross-silo 360 view of the user that included live streaming data; this data can be directly fed to Data Scientists, Analysts, or other users downstream who can immediately access and further manipulate it.
# MAGIC 
# MAGIC We just demonstrated that Databricks Delta supports batch reports, exploratory analytics, DW queries (such as aggregations on a  dataset),  and BI/interactive queries on a **single storage/copy of data**. 