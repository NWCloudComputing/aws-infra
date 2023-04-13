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
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
    cidr_blocks     = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
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
    from_port   = 443
    to_port     = 443
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

  enable_deletion_protection = false

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
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 300
    path                = "/healthz"
  }


}

resource "aws_lb_listener" "lb_listener" {

  load_balancer_arn = aws_lb.load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy      = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn = "arn:aws:acm:us-east-1:${var.account_id}:certificate/cb883211-7199-4d52-a80d-caa618db3a75"
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

resource "aws_s3_bucket" "private_s3_bucket" {
  bucket        = "my-bucket-${random_id.random.hex}"
  //acl           = "private"
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
  storage_encrypted      = true
  parameter_group_name   = aws_db_parameter_group.postgres_params.name
  vpc_security_group_ids = [aws_security_group.database.id]

  kms_key_id = aws_kms_key.rds_key.arn

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
  alarm_name          = "scaleup_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
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
  alarm_name          = "scaledown_alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 3

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscaling.name
  }

  alarm_description = "ec2 cpu utilization monitoring"
  alarm_actions     = [aws_autoscaling_policy.downautoscaling_policy.arn]

}

resource "aws_kms_key" "kms_key"{
  
  description             = "KMS key for Ebs"
  deletion_window_in_days = 10
  policy=  jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },

        {
            "Sid": "Allow access for Key Administrators",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${var.account_id}:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing",
                    "arn:aws:iam::${var.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
                ]
            },
            "Action": [
                "kms:Create*",
                "kms:Describe*",
                "kms:Enable*",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*",
                "kms:Delete*",
                "kms:TagResource",
                "kms:UntagResource",
                "kms:ScheduleKeyDeletion",
                "kms:CancelKeyDeletion"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${var.account_id}:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing",
                    "arn:aws:iam::${var.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
                ]
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow attachment of persistent resources",
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "arn:aws:iam::${var.account_id}:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing",
                    "arn:aws:iam::${var.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
                ]
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*",
            "Condition": {
                "Bool": {
                    "kms:GrantIsForAWSResource": "true"
                }
            }
        }
      ]
    })

}



resource "aws_kms_alias" "ebs_key_alias" {
  name          = "alias/ebs_key_t2"
  target_key_id = aws_kms_key.kms_key.key_id
}


#rds key

resource "aws_kms_key" "rds_key"{
  
  description             = "KMS key for rds"
  deletion_window_in_days = 10
  policy=  jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow access for Key Administrators",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
            },
            "Action": [
                "kms:Create*",
                "kms:Describe*",
                "kms:Enable*",
                "kms:List*",
                "kms:Put*",
                "kms:Update*",
                "kms:Revoke*",
                "kms:Disable*",
                "kms:Get*",
                "kms:Delete*",
                "kms:TagResource",
                "kms:UntagResource",
                "kms:ScheduleKeyDeletion",
                "kms:CancelKeyDeletion"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow use of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:DescribeKey"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow attachment of persistent resources",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.account_id}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
            },
            "Action": [
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:RevokeGrant"
            ],
            "Resource": "*",
            "Condition": {
                "Bool": {
                    "kms:GrantIsForAWSResource": "true"
                }
            }
        }

      ]
    })

}

resource "aws_kms_alias" "rds_key_alias" {
  name          = "alias/rds_key_t2"
  target_key_id = aws_kms_key.rds_key.key_id
}

# resource "aws_kms_key" "rds_kms_key" {
#    description             = "KMS key 2"
#   deletion_window_in_days = 7
# }

resource "aws_autoscaling_group" "autoscaling" {

  name                      = "csye6225-autoscaling-group"
  vpc_zone_identifier       = [aws_subnet.public-1.id, aws_subnet.public-2.id, aws_subnet.public-3.id]
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "EC2"
  force_delete              = true
  default_cooldown          = 60

  launch_template {
    id      = aws_launch_template.launch_template.id
    //version = aws_launch_template.launch_template.latest_version
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.alb_tg.arn]
  tag {
    key                 = "Key"
    value               = "Value"
    propagate_at_launch = true
  }

}

resource "aws_launch_template" "launch_template" {
  name                    = "asg_launch_config"
  image_id                = var.ami_id
  instance_type           = "t2.micro"
  key_name                = "VB"
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
      kms_key_id            = aws_kms_key.kms_key.arn # Use the ARN of your customer managed KMS key
      encrypted             = true
    }
  }

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
  name = "csye6225"
}