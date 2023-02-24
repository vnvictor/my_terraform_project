variable "ecs_cluster_id"{
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "iam_role_arn" {
  type = string
}

variable "target_value_cpu" {
  type = number
  default = 80
}

variable "target_value_memory" {
  type = number
  default = 80
}