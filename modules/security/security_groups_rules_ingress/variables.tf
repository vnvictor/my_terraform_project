variable "ingress_port" {
  type = list(string)
}
variable "protocol" {
  type = string
}
variable "sec_group_id" {
  type = string
}
variable "allowed_cidr_blocks" {
  type = list(string)
}