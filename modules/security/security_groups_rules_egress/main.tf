resource "aws_security_group_rule" "egress_rules" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = var.sec_group_id
  cidr_blocks       = var.allowed_cidr_blocks
}

