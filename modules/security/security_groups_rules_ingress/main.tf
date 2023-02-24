resource "aws_security_group_rule" "ingress_rules" {
  count = length(var.ingress_port)

  type        = "ingress"
  protocol    = var.protocol
  cidr_blocks = var.allowed_cidr_blocks
  from_port   = element(var.ingress_port, count.index)
  to_port     = element(var.ingress_port, count.index)

  security_group_id = var.sec_group_id
}

