output "private_subnets_id" {
  value = aws_subnet.private_subnets.*.id
}

output "public_subnets_id" {
  value = aws_subnet.public_subnets.*.id
}


/*
Output sample:

subnet_private_a = [
  "subnet-0f815211690156848",
  "subnet-018a5f365197af694",
]
subnet_public_a = [
  "subnet-0fb4c59ab0b87629f",
]*/