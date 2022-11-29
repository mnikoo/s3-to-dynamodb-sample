import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

args = getResolvedOptions(sys.argv, ["JOB_NAME", "INPUT_BUCKET_NAME", "INPUT_FILE_PATH", "DYNAMODB_TABLE_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

logger = glueContext.get_logger()

logger.info("*** Job has started to run")

S3bucket_node1 = glueContext.create_dynamic_frame.from_options(
    format_options={"multiline": False},
    connection_type="s3",
    format="json",
    connection_options={"paths": [f's3://{args["INPUT_BUCKET_NAME"]}/{args["INPUT_FILE_PATH"]}'], "recurse": True},
    transformation_ctx="S3bucket_node1",
)

ApplyMapping_node2 = ApplyMapping.apply(
    frame=S3bucket_node1,
    mappings=[
        ("Id.N", "string", "Id", "string"),
        ("Title.S", "string", "Title", "string"),
    ],
    transformation_ctx="ApplyMapping_node2",
)

df = ApplyMapping_node2.toDF() 

target_df = DynamicFrame.fromDF(df, glueContext, 'target_df')

glueContext.write_dynamic_frame_from_options(
    frame=target_df,
    connection_type="dynamodb",
    connection_options={
        "dynamodb.output.tableName": args["DYNAMODB_TABLE_NAME"],
        "dynamodb.throughput.write.percent": "0.9"
    }
)

logger.info("*** Job has completed")

job.commit()