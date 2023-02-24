resource "aws_security_group" "sec_group" {
  name   = var.sec_group_name
  vpc_id = var.vpc_id
}