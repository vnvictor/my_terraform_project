resource "aws_subnet" "public_subnets" {
  vpc_id            = var.vpc_id
  count             = length(var.subnets_cidr_public_list)
  cidr_block        = element(var.subnets_cidr_public_list, count.index)
  availability_zone = var.azone
}

resource "aws_route_table" "public_rtb" {
  vpc_id = var.vpc_id
  route {
    cidr_block = var.igw_cidr_block
    gateway_id = var.igw_id
  }
}

resource "aws_route_table_association" "public_rtb_assossiation" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.public_rtb.id
}

resource "aws_subnet" "private_subnets" {
  vpc_id            = var.vpc_id
  count             = length(var.subnets_cidr_private_list)
  cidr_block        = element(var.subnets_cidr_private_list, count.index)
  availability_zone = var.azone
}

resource "aws_route_table" "private_rtb" {
  vpc_id = var.vpc_id
}

resource "aws_route_table_association" "private_rtb_assossiation" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = aws_route_table.private_rtb.id
}

