provider "aws" {
  region = "eu-west-1"
}

# create a VPC
resource "aws_vpc" "vpc" {
 cidr_block = "10.0.0.0/16"

 tags = {
   Name = "kevin-eng54-vpc"
 }
}

data "external" "myipaddr" {
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}

module "app" {
  source = "./modules/app_tier"
  vpc_id = aws_vpc.vpc.id
  vpc_cb = aws_vpc.vpc.cidr_block
  name = var.app_name
  ami_id = var.app_ami_id
  my_ip = data.external.myipaddr.result.ip
  def_nacl = aws_vpc.vpc.default_network_acl_id
  db_ip = module.db.instance_ip_addr
}

module "db" {
  source = "./modules/db_tier"
  vpc_id = aws_vpc.vpc.id
  vpc_cb = aws_vpc.vpc.cidr_block
  name = var.db_name
  ami_id = var.db_ami_id
  my_ip = data.external.myipaddr.result.ip
}
