variable "project_name_prefix" {
  type    = string
  default = "s3-to-dynamodb-sample-"
}

variable "script_file_path" {
  type    = string
  default = "src/s3-to-dynamodb-job.py"
}

variable "data_files_key_prefix" {
  type    = string
  default = "data"
}

variable "dynamodb_table_name" {
  type    = string
  default = "items"
}