module "aws_user_tags" {
  custom_tags = var.tags
  environment = var.environment
  source      = "./aws_user_tags"
}