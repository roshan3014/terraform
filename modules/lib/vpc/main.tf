# =========== Create VPC ==============
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge({
    Name = "${var.env_prefix}-vpc"
  }, var.tags)
}

# =========== VPC Public Subnet ==============
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.azs[count.index]

  tags = merge({
    Name = "${var.env_prefix}-public-${count.index + 1}"
  }, var.tags)
}

# =========== VPC Private Subnet ==============
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge({
    Name = "${var.env_prefix}-private-${count.index + 1}"
  }, var.tags)
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge({
    Name = "${var.env_prefix}-igw"
  }, var.tags)
}