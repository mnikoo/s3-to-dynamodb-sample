resource "aws_cloudwatch_event_rule" "new_object_rule" {
  name        = "${var.project_name_prefix}input-file-event"

  event_pattern = <<EOF
{
  "source": ["aws.s3"],
  "detail-type": ["Object Created"],
  "detail": {
    "bucket": {
      "name": ["${aws_s3_bucket.input.bucket}"]
    },
    "object": {
      "key":[{"prefix":"data/"}]
    }
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.new_object_rule.name
  arn       = aws_lambda_function.job_runner.arn
}