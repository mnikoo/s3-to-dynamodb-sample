resource "aws_dynamodb_table" "target" {
  name           = "${var.project_name_prefix}${var.dynamodb_table_name}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "Id"
  
  attribute {
    name = "Id"
    type = "S"
  }
}
