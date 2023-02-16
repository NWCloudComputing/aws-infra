# aws-infra

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