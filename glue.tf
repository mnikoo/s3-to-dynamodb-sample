resource "aws_glue_job" "import_job" {
  name         = "${var.project_name_prefix}job"
  role_arn     = aws_iam_role.data_import_job.arn
  number_of_workers = 2
  max_retries  = 0
  timeout      = 120
  glue_version = "4.0"
  worker_type  = "G.1X"

  command {
    script_location = "s3://${aws_s3_bucket.input.bucket}/${var.script_file_path}"
    python_version  = "3"
  }

  default_arguments = {    
    "--job-language"          = "python"
    "--DYNAMODB_TABLE_NAME"   = aws_dynamodb_table.target.name
    "--INPUT_BUCKET_NAME"     = aws_s3_bucket.input.bucket
  }

  execution_property {
    max_concurrent_runs = 2
  }
}

resource "aws_iam_role" "data_import_job" {
  name = "${var.project_name_prefix}import-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "glue.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "DataImportJobRolePolicy"
    policy = data.aws_iam_policy_document.glue_job_permissions.json
  }
}

data "aws_iam_policy_document" "glue_job_permissions" {
  statement {
    sid       = "AllowS3GetObject"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.input.arn}/${var.script_file_path}", "${aws_s3_bucket.input.arn}/${var.data_files_key_prefix}/*"]
    actions   = ["s3:GetObject"]
  }
  statement {
    sid       = "AllowDynamoDBWrite"
    effect    = "Allow"
    resources = [aws_dynamodb_table.target.arn]
    actions   = ["dynamodb:DescribeTable", "dynamodb:BatchWriteItem"]
  }
  statement {
    sid       = "AllowCloudWatchCreateLogGroup"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["logs:CreateLogGroup"]
  }
  statement {
    sid       = "AllowCloudWatchWriteLogs"
    effect    = "Allow"
    resources = ["*"]
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
  }
}