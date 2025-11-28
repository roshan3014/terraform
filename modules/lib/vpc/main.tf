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
# Hosts resources that need direct internet access (e.g., Load Balancers, Bastion/public Hosts)
resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = true # Instances launched here get a public IP
  availability_zone       = var.azs[count.index]

  tags = merge({
    Name = "${var.env_prefix}-public-${count.index + 1}"
  }, var.tags)
}

# =========== VPC Private Subnet ==============
# Hosts resources that should NOT be accessible from the internet (e.g., Databases or other internal Hosts)
resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = var.azs[count.index]

  tags = merge({
    Name = "${var.env_prefix}-private-${count.index + 1}"
  }, var.tags)
}

# =========== Internet Gateway ===========
# Allows communication between the VPC and the Internet
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = merge({
    Name = "${var.env_prefix}-igw"
  }, var.tags)
}

# =========== NAT Gateway =========== (optional)
# Allows instances in the private subnet to connect to the Internet (e.g., for updates)
# but prevents inbound connections from the Internet.
resource "aws_nat_gateway" "nat" {
  count = var.single_nat_gateway ? 1 : 0 
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id = element(aws_subnet.public[*].id, count.index)
  depends_on = [ aws_internet_gateway.igw ]

}

# =========== Elastic IP for NAT Gateway ===========
# A NAT Gateway needs a public IP, which is provided by an Elastic IP (EIP)
resource "aws_eip" "nat_eip" {
  count = var.single_nat_gateway ? 1 : length(var.public_subnets)
  #vpc = true

}

# =========== Public Route Table ===========
# Routes traffic destined for the Internet (0.0.0.0/0) to the Internet Gateway.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "public_internet_access" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count = length(var.public_subnets)
  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
  }
# =========== Private Route Table ===========
# Routes traffic destined for the Internet (0.0.0.0/0) to the NAT Gateway.
resource "aws_route_table" "private" {
  count = length(var.private_subnets)
  vpc_id = aws_vpc.main.id  
}

resource "aws_route" "private_nat_gateway" {
  count = length(var.private_subnets)
  route_table_id = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"

  #single nat or one per az
 nat_gateway_id = var.enable_nat_gateway ? (
    var.single_nat_gateway ?
    aws_nat_gateway.nat[0].id :
    element(aws_nat_gateway.nat[*].id, count.index)
  ) : null
}

# Associate the Private Subnet with the Private Route Table
resource "aws_route_table_association" "private" {
  count = length(var.private_subnets)
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}