***********************Assignment3***********************

We have 4 main files here

The provider.tf contains the provider and region details

The variables.tf contains all the variables, their types and their default values.

The main.tf contains all the resources which are to be created.

The variables.tfvars is a file which passed in the command prompt to take the values like cidr blocks region etc.

To run the terraform configuration files, we have to run the following commands
1. *terraform init*  -  this command initializes the backend processes and makes the ground ready for creation.
2. *terraform apply* - this command creates all the resources listed in the config files. Before creation a confirmation is asked.
3. *Terraform destroy* - this command destroys all the created and active resources

Here, we have created 1 vpc, 3 private subnets and 3 public subnets in different availability zones but same region, 1 public route table, one private route table and 1 internet gateway.

We have included .tfvars and .terraform.lock.hcl and terraform.state in the gitignore file.




***********************Assignment 4***********************



Prerequisites: In this assignment we are setting up networking infrastructure using terraform on AWS. For that we have installed AWS CLI and terraform

Requirements and Description: users "aws_cli_dev" and "aws_cli_demo" have been created in dev and demo aws user accounts with administrator access respectively.
Now we create access keys under the security credentials of the users and configure them in the AWS CLI for each of the dev and demo profiles.

Steps to run the project:

The below commands are used to setup the virtual private cloud (vpc) network infrastructure in the AWS region as per inputs provided


1. "terraform init" - Initializes the backend and provider plugins hashicorp/aws
2. "terraform fmt" - Formats the terraform files in the directory
   
3. "terraform apply" -var-file var.tfvars" - It will setup the vpc with subnets (public and private) with the internet gateway as per the configuration provided in the main.tf file. The data.tf file contains the Availability Zones data source allows access to the list of AWS Availability Zones which can be accessed by an AWS account within the region configured in the provider. The "-var-file var.tfvars" helps in executing the application with the values defined in the var.tfvars file for the vpc cidr block, public and private subnets, profile and aws_region.
4. The EC2 instance is created in the VPC created and is attached to the github secrets configured
   
5. "terraform destroy" -var-file var.tfvars" - It will destroy the network infrastructure setup on AWS.

****************************************Assignment9****************************************

The command which we are using to upload the namecheap ssl certificate to aws is given below

$ aws --profile demo acm import-certificate --certificate fileb://Certificate.pem
      --certificate-chain fileb://CertificateChain.pem
      --private-key fileb://PrivateKey.pem

I replaced the file paths with my file path with extension names to upload the certificate.

Added 2 seperate kms keys one for ebs volumes encryption and the other for rds instance encryption.

Modified load balancer security group ingress rule to run on port 443(https).