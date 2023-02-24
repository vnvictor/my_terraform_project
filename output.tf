output "vpc_id" {
  value = module.vpc.vpc_id
}
output "subnet_public_a" {
  value = module.subnets_a.public_subnets_id
}
output "subnet_private_a" {
  value = module.subnets_a.private_subnets_id
}
output "alb" {
  value = module.app_load_balance.subnets
}