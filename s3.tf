resource "aws_s3_bucket" "input" {
  bucket_prefix = "${var.project_name_prefix}input-"
}

resource "aws_s3_bucket_acl" "input_bucket_acl" {
  bucket = aws_s3_bucket.input.id
  acl    = "private"
}

resource "aws_s3_bucket_notification" "input_bucket_notification" {
  bucket = aws_s3_bucket.input.id

  eventbridge = true
}

locals {
  local_script_file_path = "./src/glue/s3-to-dynamodb-job.py"
}

resource "aws_s3_object" "job_script" {
  bucket = aws_s3_bucket.input.bucket
  key    = "/${var.script_file_path}"
  source = local.local_script_file_path
  etag = filemd5(local.local_script_file_path)
}

resource "aws_s3_object" "data_folder" {
  bucket = aws_s3_bucket.input.bucket
  key    = "/${var.data_files_key_prefix}/"
  source = "/dev/null"
}