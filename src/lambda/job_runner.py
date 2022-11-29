import os
import logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

import boto3
client = boto3.client('glue')

glueJobName = os.environ['GLUE_JOB_NAME']

def lambda_handler(event, context):

    logger.info(f'Event: {event}')

    input_file_path = event['detail']['object']['key']

    logger.info(f'S3 object key is {input_file_path}')

    response = client.start_job_run(
        JobName = glueJobName, 
        Arguments = {
                 '--INPUT_FILE_PATH': input_file_path } )

    logger.info(f'Started AWS Glue job {glueJobName}')
    logger.info(f'AWS GLue job run id is {response["JobRunId"]}')
    return response