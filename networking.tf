data "aws_availability_zones" "available" {
    state = "available"
}
locals {
  az_a = data.aws_availability_zones.available.names[0]
  az_b = data.aws_availability_zones.available.names[1]
}

# Public Subnet
resource "aws_subnet" "public_a" {
    vpc_id = aws_vpc.main-vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone       = local.az_a
    map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-a"
  }
}

resource "aws_subnet" "public_b" {
    vpc_id = aws_vpc.main-vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone       = local.az_b
    map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-b"
  }
}


# Private Subnet
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = local.az_a

  tags = {
    Name = "private-subnet-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = local.az_b

  tags = {
    Name = "private-subnet-b"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main-vpc.id
    tags = {
    Name = "main"
  }
}

# Public Route Table
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main-vpc.id

    route {
    cidr_block = "0.0.0.0/0"
    internet_gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
    subnet_id = aws_subnet.private_a.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
    subnet_id = aws_subnet.private_b.id
    route_table_id = aws_route_table.public.id
}

# Elastic IP for NAT Gateway

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "main-nat-eip"
  }
}

# NAT Gateway in public subnet A 
resource "aws_nat_gateway" "main" {
    allocation_id = aws_eip.nat.id
    subnet_id = aws_subnet.public_a.id

    depends_on = [aws_internet_gateway.main]
   
    tags = {
    Name = "main-nat"
  }
}    

# Private route table

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}