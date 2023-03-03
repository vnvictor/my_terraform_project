variable "name" {
  type = string
}
variable "is_internal" {
  type = bool
}
variable "lb_type" {
  type = string
}
variable "alb_subnets" {
  type = list(string)
}
variable "security_group_ids" {
  type = list(string)
}

variable "target_group_info" {
  type = object({
    name              = string
    port              = number
    protocol          = string
    target_type       = string
    vpc_id            = string
    is_enable         = bool
    health_check_path = string
  })
}
