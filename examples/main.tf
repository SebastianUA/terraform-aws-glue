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

data "aws_iam_role" "admin-role" {
  name = "admin-role"
}

module "glue" {
  source      = "../../modules/glue"
  name        = "TEST"
  environment = "stage"

  # AWS Glue catalog DB
  enable_glue_catalog_database     = true
  glue_catalog_database_name       = "test-glue-db-test"
  glue_catalog_database_parameters = null

  # AWS Glue catalog table
  enable_glue_catalog_table      = true
  glue_catalog_table_name        = "test-glue-table-test"
  glue_catalog_table_description = "Those resources are managed by Terraform. Created by Vitaliy Natarov"
  glue_catalog_table_table_type  = "EXTERNAL_TABLE"
  glue_catalog_table_parameters = {
    "sizeKey"        = 493378
    "tmp"            = "none"
    "test"           = "yes"
    "classification" = "csv"
  }

  glue_catalog_table_storage_descriptor = {
    location      = "s3://my-test-bucket/test/"
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
    PASSWORD            = "examplepassword"
    USERNAME            = "exampleusername"
  }

  #glue_connection_physical_connection_requirements        = [{
  #    availability_zone       = "zone_here"
  #    security_group_id_list  = []
  #    subnet_id               = "subnet_here"
  #}]

  enable_glue_crawler = true
  glue_crawler_name   = ""
  glue_crawler_role   = data.aws_iam_role.admin-role.arn

  enable_glue_security_configuration = false
  glue_security_configuration_name   = ""
  glue_crawler_s3_target = [{
    path       = "s3://my-bucket/crowler"
    exclusions = []
  }]

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
  glue_job_execution_property = [{
    max_concurrent_runs = 2
  }]

  glue_job_command = [
    {
      script_location = "s3//test-bucket/jobs"
      name            = "jobs"
    }
  ]

  tags = map(
    "cost-center", "00-00000.000.01",
    "Project", "My Test Glue Project"
  )
}
