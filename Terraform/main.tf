

# creating vpc, cidr blocks

resource "aws_vpc" "vpc1" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc1"
  }
}

resource "aws_subnet" "public-1" {
  vpc_id     = aws_vpc.vpc1.id
  cidr_block = var.public_subnet1_cidr
  # availabilityZone = {
  #     "Fn::Select" : [ 
  #       0, 
  #       { 
  #         "Fn::GetAZs" : "us-east-1" 
  #       } 
  #     ]
  #   }
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet1"
  }
}

resource "aws_subnet" "public-2" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = var.public_subnet2_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet2"
  }
}

resource "aws_subnet" "public-3" {
  vpc_id                  = aws_vpc.vpc1.id
  cidr_block              = var.public_subnet3_cidr
  availability_zone       = data.aws_availability_zones.available.names[2]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet3"
  }
}

resource "aws_subnet" "private-1" {

  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = var.private_subnet1_cidr
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "private-subnet1"
  }
}

resource "aws_subnet" "private-2" {

  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = var.private_subnet2_cidr
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "private-subnet2"
  }
}

resource "aws_subnet" "private-3" {

  vpc_id            = aws_vpc.vpc1.id
  cidr_block        = var.private_subnet3_cidr
  availability_zone = data.aws_availability_zones.available.names[2]
  tags = {
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

resource "aws_security_group" "instance" {
  name_prefix = "instance-sd"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "database" {
  name_prefix = "db-sd"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.instance.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"] # Restrict SSH access to VPC CIDR range
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = ["0.0.0.0/0"] # Restrict SSH access to VPC CIDR range
    // security_groups = [aws_security_group.instance.id]
  }

  tags = {
    Name = "rds_database-sd"
  }
}

resource "aws_iam_policy" "webapp_s3_policy" {
  name = "WebAppS3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::my-bucket-${random_id.random.hex}",
          "arn:aws:s3:::my-bucket-${random_id.random.hex}/*",
        ]
      },
    ]
  })
}

resource "aws_s3_bucket" "private_s3_bucket" {
  bucket        = "my-bucket-${random_id.random.hex}"
  acl           = "private"
  force_destroy = true

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }


  tags = {
    Environment = "dev"
    Name        = "private_s3_bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "my_bucket_public_access_block" {
  bucket = "my-bucket-${random_id.random.hex}"

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "private_bucket_lifecycle" {
  bucket = aws_s3_bucket.private_s3_bucket.id
  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }

  rule {
    id     = "delete-empty-bucket"
    prefix = ""
    status = "Enabled"
    //abort_incomplete_multipart_upload_days = 7
    expiration {
      days = 14
    }
  }
}

resource "random_id" "random" {
  byte_length = 4
}


# Configure the PostgreSQL parameter group
resource "aws_db_parameter_group" "postgres_params" {
  name_prefix = "csye6225-postgres-params"
  family      = "postgres13"

  parameter {
    apply_method = "pending-reboot"
    name         = "max_connections"
    value        = "100"
  }

  parameter {
    apply_method = "pending-reboot"
    name         = "shared_buffers"
    value        = "16"
  }
}



# Create the RDS instance
resource "aws_db_instance" "rds_instance" {
  engine                 = "postgres"
  engine_version         = "13.3"
  instance_class         = "db.t3.micro"
  multi_az               = false
  allocated_storage      = 20
  identifier             = "csye6225"
  db_name                = var.db_host
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = "private-rds-subnet-group"
  publicly_accessible    = false
  skip_final_snapshot    = true
  parameter_group_name   = aws_db_parameter_group.postgres_params.name
  vpc_security_group_ids = [aws_security_group.database.id]

  tags = {
    Name = "csye6225-rds"
  }
}

resource "aws_db_subnet_group" "private_rds_subnet_group" {
  name        = "private-rds-subnet-group"
  description = "Private subnet group for RDS instances"
  subnet_ids  = [aws_subnet.private-1.id, aws_subnet.private-2.id]
}


resource "aws_instance" "Terraform_Managed" {
  ami                         = var.ami_id
  instance_type               = "t2.micro"
  key_name                    = "SD"
  subnet_id                   = aws_subnet.public-1.id
  vpc_security_group_ids      = [aws_security_group.instance.id]
  associate_public_ip_address = true # enable public IP and DNS for the instance
  disable_api_termination     = false
  user_data = <<-EOF
#!/bin/bash
cd /home/ec2-user
touch ./.env

echo "DB_HOST=$(echo ${aws_db_instance.rds_instance.endpoint} | cut -d ':' -f 1)" >> .env
echo "DB_USER=${aws_db_instance.rds_instance.username}" >> .env
echo "DB_PASSWORD=${aws_db_instance.rds_instance.password}" >> .env
echo "S3_BUCKET_NAME=${aws_s3_bucket.private_s3_bucket.bucket}" >> .env

source ./.env

EOF

  root_block_device {
    volume_size           = 50 # root volume size in GB
    delete_on_termination = true
  }


  tags = {
    Name = "Terraform Managed EC2 Instance"
  }

  count = 1
  lifecycle {
    ignore_changes = [subnet_id]
  }

  availability_zone    = data.aws_availability_zones.available.names[0]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

}

resource "aws_iam_role" "ec2_csye6225_role" {
  name = "EC2-CSYE6225"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "EC2-CSYE6225-Role"
  }
}

resource "aws_iam_role_policy_attachment" "webapp_s3_policy_attachment" {
  policy_arn = aws_iam_policy.webapp_s3_policy.arn
  role       = aws_iam_role.ec2_csye6225_role.name
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2-CSYE6225-Instance-Profile"

  role = aws_iam_role.ec2_csye6225_role.name
}

