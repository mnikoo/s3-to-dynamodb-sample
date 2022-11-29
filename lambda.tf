data "archive_file" "job_runner_lambda_archive" {
  type        = "zip"
  source_file = "${path.module}/src/lambda/job_runner.py"
  output_path = "${path.module}/src/lambda/job_runner.py.zip"
}

resource "aws_lambda_function" "job_runner" {
  function_name = "${var.project_name_prefix}job-runner"
  handler = "job_runner.lambda_handler"
  role = aws_iam_role.job_runner_lambda_execution_role.arn
  runtime = "python3.8"

  filename = data.archive_file.job_runner_lambda_archive.output_path
  source_code_hash = data.archive_file.job_runner_lambda_archive.output_base64sha256

  timeout = 5
  memory_size = 128

  reserved_concurrent_executions = 1

  environment {
    variables = {
      GLUE_JOB_NAME = aws_glue_job.import_job.name
    }
  }
}

resource "aws_iam_role" "job_runner_lambda_execution_role" {
  name = "${var.project_name_prefix}job-runner-lambda-execution-role"
  assume_role_policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement =  [
        {
          Effect = "Allow",
          Principal = {
            Service = "lambda.amazonaws.com"
          },
          Action = "sts:AssumeRole"
        }
      ]
    }
  )
}

resource "aws_lambda_permission" "allow_eventbridge_to_invoke" {
  statement_id  = "AllowExecutionFromEventBridgeRule"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.job_runner.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.new_object_rule.arn
  source_account = data.aws_caller_identity.current.account_id
}

resource "aws_iam_role_policy_attachment" "job_runner_lambda_execution" {
  role = aws_iam_role.job_runner_lambda_execution_role.name
  policy_arn = aws_iam_policy.job_runner.arn
}

resource "aws_iam_policy" "job_runner" {
  name = "${var.project_name_prefix}job-runner-lambda-execution-policy"
  policy = data.aws_iam_policy_document.job_runner.json
}

locals {
  cloud_watch_arn = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.job_runner.function_name}:*"
}

data "aws_iam_policy_document" "job_runner" {
  statement {
    sid       = "AllowCloudWatchCreateLogGroup"
    effect    = "Allow"
    resources = [local.cloud_watch_arn]
    actions   = ["logs:CreateLogGroup"]
  }
  statement {
    sid       = "AllowCloudWatchWriteLogs"
    effect    = "Allow"
    resources = [local.cloud_watch_arn]
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
  }
  statement {
    sid       = "AllowRunGlueJob"
    effect    = "Allow"
    resources = [aws_glue_job.import_job.arn]
    actions   = ["glue:StartJobRun"]
  }
}