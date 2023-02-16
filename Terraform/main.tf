

# creating vpc, cidr blocks

resource "aws_vpc" "vpc1" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags ={
    Name = "vpc1"
  }
}

resource "aws_subnet" "public-1" {
  vpc_id = aws_vpc.vpc1.id
  cidr_block = var.public_subnet1_cidr
  # availabilityZone = {
  #     "Fn::Select" : [ 
  #       0, 
  #       { 
  #         "Fn::GetAZs" : "us-east-1" 
  #       } 
  #     ]
  #   }
 availability_zone =  data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags ={
    Name = "public-subnet1"
  }
}

resource "aws_subnet" "public-2" {
  vpc_id = aws_vpc.vpc1.id
  cidr_block = var.public_subnet2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
    tags ={
    Name = "public-subnet2"
  }
}

resource "aws_subnet" "public-3" {
  vpc_id = aws_vpc.vpc1.id
  cidr_block = var.public_subnet3_cidr
  availability_zone = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = true
    tags ={
    Name = "public-subnet3"
  }
}

resource "aws_subnet" "private-1" {
  
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = var.private_subnet1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
    tags ={
    Name = "private-subnet1"
  }
}

resource "aws_subnet" "private-2" {
  
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = var.private_subnet2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]
    tags ={
    Name = "private-subnet2"
  }
}

resource "aws_subnet" "private-3" {
  
  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = var.private_subnet3_cidr
  availability_zone = data.aws_availability_zones.available.names[2]
    tags ={
    Name = "private-subnet3"
  }
}

resource "aws_internet_gateway" "dev-gw" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    Name = "dev-main"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc1.id
  route {
    cidr_block = var.public_routetable_cidr
    gateway_id = aws_internet_gateway.dev-gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc1.id


  tags = {
    Name = "private-route-table"
  }
}

resource "aws_route_table_association" "private_association1" {
  

  subnet_id      = aws_subnet.private-1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_association2" {
  

  subnet_id      = aws_subnet.private-2.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_association3" {
  

  subnet_id      = aws_subnet.private-3.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public_association1" {
 

  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_association2" {
 

  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_association3" {
 

  subnet_id      = aws_subnet.public-3.id
  route_table_id = aws_route_table.public.id
}