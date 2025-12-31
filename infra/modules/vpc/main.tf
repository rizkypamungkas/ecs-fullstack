// MAIN VPC //

resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    name = "${var.name}_vpc"
  }
}

// INTERNET GATEWAY //

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    name = "${var.name}_igw"
  }
}

// PUBLIC SUBNET //

data "aws_availability_zones" "available" {}

resource "aws_subnet" "main_public_subnet" {
  count                   = length(var.public_subnet)
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    name = "public_subnet_$(count.index)"
  }
}

// PUBLIC SUBNET ROUTE TABLE //

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    name = "public subnet route table"
  } 
}

// ASSOC ROUTE TABLE TO PUBLIC SUBNET //

resource "aws_route_table_association" "public_subnet_association" {
  count           = length(var.public_subnet)
  subnet_id       = aws_subnet.main_public_subnet[count.index].id
  route_table_id  = aws_route_table.public_rt.id
}

// PRIVATE SUBNET //

resource "aws_subnet" "main_private_subnet" {
  count             = length(var.private_subnet)
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

// ELASTIC IP //

resource "aws_eip" "eip_nat_gw" {
  tags = {
    name = "nat eip"
  }
} 

// NAT GATEWAY //

resource "aws_nat_gateway" "main_nat_gw" {
  allocation_id = aws_eip.eip_nat_gw.id
  subnet_id     = aws_subnet.main_public_subnet[0].id
  tags = {
    name = "main nat gateway"
  }
  
  depends_on = [aws_internet_gateway.main_igw] # to ensure internet gateway create first
}

// PRIVATE SUBNET ROUTE TABLE //

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main_nat_gw.id
  }

  tags = {
    name = "private subnet route table"
  } 
}

//  ASSOC PRIVATE ROUTE TABLE TO PRIVATE SUBNET //

resource "aws_route_table_association" "private_subnet_association" {
  count          = length(var.private_subnet)
  subnet_id      = aws_subnet.main_private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}
