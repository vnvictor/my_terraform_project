variable "vpc_id" {
  type = string
}

variable "azone" {
  type = string
}

variable "subnets_cidr_public_list" {
  type = list(string)
}

variable "subnets_cidr_private_list" {
  type = list(string)
}

variable "igw_cidr_block" {
  type = string
}
variable "igw_id" {
  type = string
}