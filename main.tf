terraform {
  backend "local" { path = "./statefiles/terraform.tfstate" }
}

provider "aws" {
  region = "us-east-1"
}

locals {
  region                = "us-east-1"
  av_zone               = ["${local.region}a", "${local.region}b"]
  vpc_cidr_block        = "10.0.0.0/21"
  igw_cidr_block        = "0.0.0.0/0"
  vpc_instance_tenance  = "default"
  public_subnet_a_list  = ["10.0.1.0/24"]
  private_subnet_a_list = ["10.0.2.0/24"] #, "10.0.3.0/24"]
  public_subnet_b_list  = ["10.0.4.0/24"]
  private_subnet_b_list = ["10.0.5.0/24"] #, "10.0.6.0/24"]
  container_image_name  = "apache"
  container_image       = "382711225776.dkr.ecr.us-east-1.amazonaws.com/myapache:latest"
  container_port        = 443
}

module "vpc" {
  source           = "./modules/vpc"
  vpc_cidr_block   = local.vpc_cidr_block
  instance_tenancy = local.vpc_instance_tenance
}

module "subnets_a" {
  source                    = "./modules/subnets"
  vpc_id                    = module.vpc.vpc_id
  azone                     = local.av_zone[0]
  subnets_cidr_public_list  = local.public_subnet_a_list
  subnets_cidr_private_list = local.private_subnet_a_list
  igw_cidr_block            = local.igw_cidr_block
  igw_id                    = module.vpc.internet_gateway_id
}

module "subnets_b" {
  source                    = "./modules/subnets"
  vpc_id                    = module.vpc.vpc_id
  azone                     = local.av_zone[1]
  subnets_cidr_public_list  = local.public_subnet_b_list
  subnets_cidr_private_list = local.private_subnet_b_list
  igw_cidr_block            = local.igw_cidr_block
  igw_id                    = module.vpc.internet_gateway_id
}

/* SG EGRESS ALL */

module "security_group_egress" {
  source         = "./modules/security/security_groups"
  vpc_id         = module.vpc.vpc_id
  sec_group_name = "security_group_egress"
}

module "sg_egress_rules" {
  source              = "./modules/security/security_groups_rules_egress"
  sec_group_id        = module.security_group_egress.security_group_id
  allowed_cidr_blocks = ["${local.igw_cidr_block}"]
}

/* SG RULES For HTTP ACCESS*/

module "security_group_http" {
  source         = "./modules/security/security_groups"
  vpc_id         = module.vpc.vpc_id
  sec_group_name = "my_sec_group"
}

module "security_group_http_ingress" {
  source              = "./modules/security/security_groups_rules_ingress"
  ingress_port        = ["443"]
  protocol            = "TCP"
  allowed_cidr_blocks = ["${local.igw_cidr_block}"]
  sec_group_id        = module.security_group_http.security_group_id
}

/* SG RULES For Containers*/

module "containers_security_group" {
  source         = "./modules/security/security_groups"
  vpc_id         = module.vpc.vpc_id
  sec_group_name = "containers_sec_group"
}

module "containers_security_group_health_check" {
  source              = "./modules/security/security_groups_rules_ingress"
  ingress_port        = ["${local.container_port}"]
  protocol            = "TCP"
  allowed_cidr_blocks = ["${local.igw_cidr_block}"]
  sec_group_id        = module.containers_security_group.security_group_id
}

/* SG Rules for VPC ENDPOINT - ALLOW TRAFFIC THROUGH 443 Port */

module "vpc_ecr_endpoint_security_group" {
  source         = "./modules/security/security_groups"
  vpc_id         = module.vpc.vpc_id
  sec_group_name = "vpc_ecr_endpoint_sec_group"
}

module "vpc_ecr_endpoint_ingress_rule" {
  source              = "./modules/security/security_groups_rules_ingress"
  ingress_port        = ["443"]
  protocol            = "TCP"
  allowed_cidr_blocks = ["${local.vpc_cidr_block}"]
  sec_group_id        = module.vpc_ecr_endpoint_security_group.security_group_id
}

/* Task Roles  */

module "ecs_task_execution_role" {
  source = "./modules/security/iam_policies"
  policy_document_info = {
    actions     = ["sts:AssumeRole"]
    effect      = "Allow"
    type        = "Service"
    identifiers = ["ecs-tasks.amazonaws.com"]
  }
  iam_policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  iam_role_name  = "task-execution-role"
}

module "ecs_autoscale_role" {
  source = "./modules/security/iam_policies"
  policy_document_info = {
    actions     = ["sts:AssumeRole"]
    effect      = "Allow"
    type        = "Service"
    identifiers = ["application-autoscaling.amazonaws.com"]
  }
  iam_policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
  iam_role_name  = "ecs-scale-application"
}

/* APLICATION LOAD BALANCER */

module "app_load_balance" {
  depends_on = [
    module.vpc,
    module.subnets_a,
    module.subnets_b
  ]
  source = "./modules/alb"

  name               = "myalb"
  is_internal        = false
  lb_type            = "application"
  security_group_ids = [
    "${module.containers_security_group.security_group_id}",
    "${module.security_group_egress.security_group_id}"
  ]
  alb_subnets        = concat(module.subnets_a.public_subnets_id, module.subnets_b.public_subnets_id)

  target_group_info = {
    health_check_path = "/"
    is_enable         = true
    name              = "apache"
    port              = local.container_port
    protocol          = "HTTP"
    target_type       = "ip"
    vpc_id            = module.vpc.vpc_id
  }
}

module "ecs_cluster" {
  source           = "./modules/ecs_cluster"
  ecs_cluster_name = "ecs_cluster"
}

module "ecs" {
  depends_on = [
    module.app_load_balance,
    module.ecs_task_execution_role,
    module.ecs_autoscale_role,
    module.ecs_cluster
  ]
  source = "./modules/ecs"

  task_definition_info = {
    family                   = "ecs-task-family"
    container_image_name     = local.container_image_name
    container_image          = local.container_image
    cpu                      = "256"
    memory                   = "1024"
    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    container_image_port     = local.container_port
    execution_role_arn       = "${module.ecs_task_execution_role.iam_role_arn}"
  }

  ecs_service_info = {
    name          = "ecs_fargate_service"
    cluster_id    = "${module.ecs_cluster.ecs_cluster_id}"
    launch_type   = "FARGATE"
    desired_count = 2

    load_balancer = {
      target_group_arn     = module.app_load_balance.target_group_arn
      container_image_name = local.container_image_name
      container_image_port = local.container_port
    }

    network_configuration = {
      assign_public_ip = false
      security_groups  = [
        "${module.security_group_http.security_group_id}", 
        "${module.security_group_egress.security_group_id}"
      ]
      subnets          = concat(module.subnets_a.private_subnets_id, module.subnets_b.private_subnets_id)
    }
  }
}
/*
module "ecs_autoscaling" {
  depends_on = [
    module.ecs,
    module.ecs_autoscale_role
  ]
  source = "./modules/autoscaling"
  ecs_cluster_id = module.ecs_cluster.ecs_cluster_id
  ecs_service_name = module.ecs.ecs_service_name
  iam_role_arn = "${module.ecs_autoscale_role.iam_role_arn}"
  target_value_cpu = 60
  target_value_memory = 60
}
*/

resource "aws_vpc_endpoint" "ecr_endpoint" {
  depends_on = [
    module.vpc,
    module.app_load_balance,
    module.ecs
  ]
  vpc_id              = module.vpc.vpc_id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${local.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [
    "${module.vpc_ecr_endpoint_security_group.security_group_id}",
    "${module.security_group_egress.security_group_id}"
  ]
  subnet_ids = concat(module.subnets_a.private_subnets_id, module.subnets_b.private_subnets_id)
}

resource "aws_vpc_endpoint" "ecr_api_endpoint" {
  depends_on = [
    module.vpc,
    module.app_load_balance,
    module.ecs
  ]
  vpc_id              = module.vpc.vpc_id
  private_dns_enabled = true
  service_name        = "com.amazonaws.${local.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  security_group_ids = [
    "${module.vpc_ecr_endpoint_security_group.security_group_id}",
    "${module.security_group_egress.security_group_id}"
  ]
  subnet_ids = concat(module.subnets_a.private_subnets_id, module.subnets_b.private_subnets_id)
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${local.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = ["${module.subnets_a.private_subnets_rtb_id}", "${module.subnets_b.private_subnets_rtb_id}"]
}

/*
*/