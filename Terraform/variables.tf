variable "region" {
  default = "us-east-1"
  type        = string
  description = "Region of the VPC"
}

# variable "access_key" {
#      description = "Access key to AWS console"
     
# }
# variable "secret_key" {
#      description = "Secret key to AWS console"
     
# }

variable "cidr_block" { 
  default = "10.0.0.0/16"
  type        = string
  description = "CIDR block for the VPC"
}

variable "profile" {
  default = "dev"
    type = string
  
}

variable "public_subnet1_cidr" {
default = "10.0.1.0/24"
  type        = string
  description = "List of public subnet CIDR blocks"
}

variable "public_subnet2_cidr" {
default = "10.0.2.0/24"
  type        = string
  description = "List of public subnet CIDR blocks"
}

variable "public_subnet3_cidr" {
default = "10.0.3.0/24"
  type        = string
  description = "List of public subnet CIDR blocks"
}

variable "private_subnet1_cidr" {
 default = "10.0.4.0/24"
  type        = string
  description = "List of private subnet CIDR blocks"
}

variable "private_subnet2_cidr" {
 default = "10.0.5.0/24"
  type        = string
  description = "List of private subnet CIDR blocks"
}

variable "private_subnet3_cidr" {
 default = "10.0.6.0/24"
  type        = string
  description = "List of private subnet CIDR blocks"
}

variable "private_routetable_cidr" {
  default = "0.0.0.0/0"
  type = string
  description = "Private route table cidr block"
}

variable "public_routetable_cidr" {
  default = "0.0.0.0/0"
  type = string
  description = "Public route table cidr block"
}

# variable "availability_zones" {
#  default = "us-east-1a"
#   type        = list
#   description = "List of availability zones"
# }

data "aws_availability_zones" "available" {
  state = "available"
}