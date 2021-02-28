#
# MAINTAINER Vitaliy Natarov "vitaliy.natarov@yahoo.com"
#
terraform {
  required_version = "~> 0.13"
}

provider "aws" {
  region                  = "us-east-1"
  shared_credentials_file = pathexpand("~/.aws/credentials")
}

variable "glue_connection_user_name" {
  type        = string
  description = "Glue connection user name"
  default     = "ChangeMeASAP!orElse"
}

variable "glue_connection_password" {
  type        = string
  description = "Glue connection password"
  default     = "exampleglueusername"
}

variable "example_tags" {
  type        = map(any)
  description = "Tag values for this example"
  default = {
    "cost-center" = "00-00000.000.01"
    "Project"     = "My Test Glue Project"
  }
}

# Get the usera and account information
data "aws_caller_identity" "current" {
}

# Get the correct AWS partition values can be:
#     "aws"        - Public AWS partition 
#     "aws-cn"     - AWS China partition
#     "aws-us-gov" - US Government partition
data "aws_partition" "current" {
}

#Create example glue service policy from template
resource "aws_iam_policy" "glue_example_service_policy" {
  name        = "glue_example_service_policy"
  path        = "/"
  description = "Example Glue Service Policy"
  policy = templatefile(
    "./templates/json/glue_service_policy.json",
    {
      partition = data.aws_partition.current.partition
    }
  )
}

# Create example glue user policy from template
resource "aws_iam_policy" "glue_example_user_policy" {
  name        = "glue_example_user_policy"
  path        = "/"
  description = "Example Glue User Policy"
  policy = templatefile(
    "./templates/json/glue_user_policy.json",
    {
      partition = data.aws_partition.current.partition
    }
  )
}

# Create example glue administrator role
resource "aws_iam_role" "glue_example_admin_role" {
  name = "glue_example_role"
  assume_role_policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "glue.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )
}

# Attach AWS managed policy: AWSCloudFormationReadOnlyAccess
resource "aws_iam_role_policy_attachment" "AWSCloudFormationReadOnlyAccess" {
  role       = aws_iam_role.glue_example_admin_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_partition.current.partition}:policy/AWSCloudFormationReadOnlyAccess"
}

# Attach AWS managed policy: AWSGlueConsoleFullAccess
resource "aws_iam_role_policy_attachment" "AWSGlueConsoleFullAccess" {
  role       = aws_iam_role.glue_example_admin_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_partition.current.partition}:policy/AWSGlueConsoleFullAccess"
}

# Attach AWS managed policy: AWSGlueConsoleSageMakerNotebookFullAccess
resource "aws_iam_role_policy_attachment" "AWSGlueConsoleSageMakerNotebookFullAccess" {
  role       = aws_iam_role.glue_example_admin_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_partition.current.partition}:policy/AWSGlueConsoleSageMakerNotebookFullAccess"
}

# Attach AWS managed policy: AWSGlueSchemaRegistryFullAccess
resource "aws_iam_role_policy_attachment" "AWSGlueSchemaRegistryFullAccess" {
  role       = aws_iam_role.glue_example_admin_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_partition.current.partition}:policy/AWSGlueSchemaRegistryFullAccess"
}

# Attach AWS managed policy: AmazonAthenaFullAccess
resource "aws_iam_role_policy_attachment" "AmazonAthenaFullAccess" {
  role       = aws_iam_role.glue_example_admin_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_partition.current.partition}:policy/AmazonAthenaFullAccess"
}

# Attach AWS managed policy: AmazonS3FullAccess
resource "aws_iam_role_policy_attachment" "AmazonS3FullAccess" {
  role       = aws_iam_role.glue_example_admin_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_partition.current.partition}:policy/AmazonS3FullAccess"
}

# Attach AWS managed policy: CloudWatchLogsReadOnlyAccess
resource "aws_iam_role_policy_attachment" "CloudWatchLogsReadOnlyAccess" {
  role       = aws_iam_role.glue_example_admin_role.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::${data.aws_partition.current.partition}:policy/CloudWatchLogsReadOnlyAccess"
}

# Get reference to the role to be used by the module below
data "aws_iam_role" "admin-role" {
  name = aws_iam_role.glue_example_admin_role.name
}

# Create glue catalog bucket (account_id ensures unique name across accounts)
resource "aws_s3_bucket" "glue_catalog" {
  bucket = "glue_catalog-${data.aws_caller_identity.current.account_id}"
  acl    = "private"
  tags   = var.example_tags
}

# Create test folder in the bucket
resource "aws_s3_bucket_object" "test_object" {
  bucket = aws_s3_bucket.glue_catalog.id
  key    = "/test"
}

# Create glue crawler bucket (account_id ensures unique name across accounts)
resource "aws_s3_bucket" "glue_crawler" {
  bucket = "glue_crawler-${data.aws_caller_identity.current.account_id}"
  acl    = "private"
  tags   = var.example_tags
}

# Create crawler folder in the bucket
resource "aws_s3_bucket_object" "crawler_object" {
  bucket = aws_s3_bucket.glue_crawler.id
  key    = "/crawler"
}

# Create Glue job bucket (account_id ensures unique name across accounts)
resource "aws_s3_bucket" "glue_jobs" {
  bucket = "glue_crawler-${data.aws_caller_identity.current.account_id}"
  acl    = "private"
  tags   = var.example_tags
}

# Create jobs folder in the bucket
resource "aws_s3_bucket_object" "jobs_object" {
  bucket = aws_s3_bucket.glue_jobs.id
  key    = "/jobs"
}

# terraform-aws-glue module
module "glue" {
  source      = "/Users/gregorymirsky/terraform-aws-glue"
  name        = "TEST"
  environment = "STAGE"
  # AWS Glue catalog DB
  enable_glue_catalog_database     = true
  glue_catalog_database_name       = "test-glue-db-${data.aws_caller_identity.current.account_id}"
  glue_catalog_database_parameters = null
  # AWS Glue catalog table
  enable_glue_catalog_table      = true
  glue_catalog_table_name        = "test-glue-table-${data.aws_caller_identity.current.account_id}"
  glue_catalog_table_description = "Those resources are managed by Terraform. Created by Vitaliy Natarov"
  glue_catalog_table_table_type  = "EXTERNAL_TABLE"
  glue_catalog_table_parameters = {
    "sizeKey"        = 493378
    "tmp"            = "none"
    "test"           = "yes"
    "classification" = "csv"
  }
  glue_catalog_table_storage_descriptor = {
    location      = "s3://${aws_s3_bucket.glue_catalog.id}/test"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
  }
  storage_descriptor_columns = [
    {
      columns_name    = "oid"
      columns_type    = "double"
      columns_comment = "oid"
    },
    {
      columns_name    = "oid2"
      columns_type    = "double"
      columns_comment = "oid2"
    },
    {
      columns_name    = "oid3"
      columns_type    = "double"
      columns_comment = "oid3"
    },
  ]
  storage_descriptor_ser_de_info = [
    {
      ser_de_info_name                  = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      ser_de_info_serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      ser_de_info_parameters            = map("field.delim", ",")
    }
  ]
  storage_descriptor_skewed_info = [
    {
      ser_de_info_name                  = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      ser_de_info_serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      ser_de_info_parameters            = map("field.delim", ",")
    }
  ]
  storage_descriptor_sort_columns = []
  # AWS Glue connection
  enable_glue_connection = true
  glue_connection_connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:mysql://aws_rds_cluster.example.endpoint/exampledatabase"
    PASSWORD            = var.glue_connection_password
    USERNAME            = var.glue_connection_user_name
  }
  ##glue_connection_physical_connection_requirements        = [{
  #    availability_zone       = "zone_here"
  #    security_group_id_list  = []
  #    subnet_id               = "subnet_here"
  #}]
  enable_glue_crawler                = true
  glue_crawler_name                  = ""
  glue_crawler_role                  = data.aws_iam_role.admin-role.arn
  enable_glue_security_configuration = false
  glue_security_configuration_name   = ""
  glue_crawler_s3_target = [
    {
      path       = "s3://${aws_s3_bucket.glue_crawler.id}/crawler"
      exclusions = []
    }
  ]
  enable_glue_trigger = true
  glue_trigger_actions = [
    {
      trigger_name = ""
    }
  ]
  enable_glue_job                 = true
  glue_job_name                   = ""
  glue_job_role_arn               = data.aws_iam_role.admin-role.arn
  glue_job_additional_connections = []
  glue_job_execution_property = [
    {
      max_concurrent_runs = 2
    }
  ]
  glue_job_command = [
    {
      script_location = "s3//${aws_s3_bucket.glue_jobs.id}/jobs"
      name            = "jobs"
    }
  ]
  tags = var.example_tags
}
