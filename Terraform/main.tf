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
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    security_groups = [aws_security_group.load_balancer.id ]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 3000
    to_port   = 3000
    protocol  = "tcp"
    security_groups = [aws_security_group.load_balancer.id ]
   // cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_security_group" "load_balancer" {
  name_prefix = "lb-sd"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Load Balancer"
  }
}

resource "aws_lb" "load_balancer" {
  name               = "loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = [aws_subnet.public-1.id, aws_subnet.public-2.id, aws_subnet.public-3.id]

  enable_deletion_protection = true

  tags = {
    Environment = "loadbalancer"
  }
}

resource "aws_lb_target_group" "alb_tg" {

  name        = "csye6225-lb-alb-tg"
  port        = "3000"
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.vpc1.id

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 300
    path                = "/healthz"
  }


}

resource "aws_lb_listener" "lb_listener" {

  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn
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
          "s3:ListBucket",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "cloudwatch:PutMetricData",
          "ec2:DescribeTags",
          "application-autoscaling:*"
        ]
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::my-bucket-${random_id.random.hex}",
          "arn:aws:s3:::my-bucket-${random_id.random.hex}/*"
        ]
      },
    ]
  })
}


# resource "aws_iam_policy" "cloudwatch_agent_policy" {
#   name = "CloudWatchAgentPolicy"
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "cloudwatch:GetMetricStatistics",
#           "cloudwatch:GetMetricData",
#           "cloudwatch:ListMetrics",
#           "cloudwatch:PutMetricData",
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ]
#         Effect   = "Allow"
#         Resource = ["*"]
#       },
#     ]
#   })
# }

resource "aws_s3_bucket" "private_s3_bucket" {
  bucket        = "my-bucket-${random_id.random.hex}"
  acl           = "private"
  force_destroy = true

  tags = {
    Environment = "dev"
    Name        = "private_s3_bucket"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.private_s3_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
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

resource "aws_db_subnet_group" "private_rds_subnet_group" {
  name        = "private-rds-subnet-group"
  description = "Private subnet group for RDS instances"
  subnet_ids  = [aws_subnet.private-1.id, aws_subnet.private-2.id]

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
  db_subnet_group_name   = aws_db_subnet_group.private_rds_subnet_group.name
  publicly_accessible    = false
  skip_final_snapshot    = true
  parameter_group_name   = aws_db_parameter_group.postgres_params.name
  vpc_security_group_ids = [aws_security_group.database.id]

  tags = {
    Name = "csye6225-rds"
  }
}

resource "aws_autoscaling_policy" "upautoscaling_policy" {
  name                   = "upautoscaling_policy"
  scaling_adjustment     = 1
  adjustment_type        = "PercentChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.autoscaling.name
}

resource "aws_cloudwatch_metric_alarm" "scaleuppolicyalarm" {
  alarm_name          = "scaleuppolicyalarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 5

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscaling.name
  }

  alarm_description = "ec2 cpu utilization monitoring"
  alarm_actions     = [aws_autoscaling_policy.upautoscaling_policy.arn]
}

resource "aws_autoscaling_policy" "downautoscaling_policy" {
  name                   = "downautoscaling_policy"
  scaling_adjustment     = -1
  adjustment_type        = "PercentChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.autoscaling.name
}

resource "aws_cloudwatch_metric_alarm" "scaledownpolicyalarm" {
  alarm_name          = "scaledownpolicyalarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 3

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscaling.name
  }

  alarm_description = "ec2 cpu utilization monitoring"
  alarm_actions     = [aws_autoscaling_policy.downautoscaling_policy.arn]
}

resource "aws_autoscaling_group" "autoscaling" {

  name                      = "csye6225-asg-spring2023"
  vpc_zone_identifier       = [aws_subnet.public-1.id,aws_subnet.public-2.id,aws_subnet.public-3.id]
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true
  default_cooldown          = 60

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }
  target_group_arns = [aws_lb_target_group.alb_tg.arn]
  tag {
    key                 = "Key"
    value               = "Value"
    propagate_at_launch = true
  }

}

resource "aws_launch_template" "launch_template" {
  name          = "asg_launch_config"
  image_id      = var.ami_id
  instance_type = "t2.micro"
  key_name ="VB"
  disable_api_termination = true
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.instance.id]
    subnet_id                   = aws_subnet.public-1.id
  }

  user_data = base64encode(templatefile("userdata.sh", {
    DB_HOST        = "${aws_db_instance.rds_instance.endpoint}"
    DB_USER        = "${aws_db_instance.rds_instance.username}"
    DB_PASSWORD    = "${aws_db_instance.rds_instance.password}"
    S3_BUCKET_NAME = "${aws_s3_bucket.private_s3_bucket.bucket}"
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      volume_size           = 50
      volume_type           = "gp2"
    }
  }

}

 
# resource "aws_instance" "Terraform_Managed" {
#   ami                         = var.ami_id
#   instance_type               = "t2.micro"
#   key_name                    = "VB"
#   subnet_id                   = aws_subnet.public-1.id
#   vpc_security_group_ids      = [aws_security_group.instance.id]
#   associate_public_ip_address = true # enable public IP and DNS for the instance
#   disable_api_termination     = false
#   depends_on = [
#     aws_db_instance.rds_instance
#   ]
#   user_data = <<-EOF
# #!/bin/bash
# cd /home/ec2-user/script
# touch ./.env

# echo "DB_HOST=$(echo ${aws_db_instance.rds_instance.endpoint} | cut -d ':' -f 1)" >> .env
# echo "DB_USER=${aws_db_instance.rds_instance.username}" >> .env
# echo "DB_PASSWORD=${aws_db_instance.rds_instance.password}" >> .env
# echo "S3_BUCKET_NAME=${aws_s3_bucket.private_s3_bucket.bucket}" >> .env

# sudo su
# cd /
# mkdir ./upload
# sudo chown ec2-user:ec2-user /home/ec2-user/script/*
# sudo systemctl stop node.service
# sudo systemctl daemon-reload
# sudo systemctl enable node.service
# sudo systemctl start node.service

# source ./.env

# EOF

#   root_block_device {
#     volume_size           = 50 # root volume size in GB
#     delete_on_termination = true
#   }


#   tags = {
#     Name = "Terraform Managed EC2 Instance"
#   }


#   lifecycle {
#     ignore_changes = [subnet_id]
#   }

#   availability_zone    = data.aws_availability_zones.available.names[0]
#   iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

# }

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
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "EC2-CSYE6225-Role"
  }
}

data "aws_region" "current" {}

resource "aws_iam_role_policy_attachment" "webapp_s3_policy_attachment" {
  policy_arn = aws_iam_policy.webapp_s3_policy.arn
  role       = aws_iam_role.ec2_csye6225_role.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attachment" {
  //  name       = "cloudwatch_policy_attachment"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.ec2_csye6225_role.name
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "EC2-CSYE6225-Instance-Profile"

  role = aws_iam_role.ec2_csye6225_role.name
}




# output "public_ip" {
#   value = aws_instance.Terraform_Managed.public_ip
# }


data "aws_route53_zone" "main-route" {
  name = var.domain_name
}

resource "aws_route53_record" "web" {
  name    = var.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.main-route.zone_id

  alias {
    name                   = aws_lb.load_balancer.dns_name
    zone_id                = aws_lb.load_balancer.zone_id
    evaluate_target_health = true
  }


  #ttl = 60
  # records = [
  #   aws_instance.Terraform_Managed.public_ip,
  # ]
}

resource "aws_cloudwatch_log_group" "csye6225" {
  name ="csye6225"
}