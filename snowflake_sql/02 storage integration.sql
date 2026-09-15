CREATE STORAGE INTEGRATION IF NOT EXISTS walmart_s3_int
TYPE=EXTERNAL_STAGE
STORAGE_PROVIDER='S3'
ENABLED=TRUE
STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::941377112484:role/walmart-pipeline-snowflake-role'
STORAGE_ALLOWED_LOCATIONS=('s3://walmart-pipeline-raw-manual/')

desc storage integration walmart_s3_int