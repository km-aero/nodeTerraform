provider "aws" {
  region = "eu-west-1"
}

data "external" "myipaddr" {
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}

# create a VPC
resource "aws_vpc" "app_vpc" {
 cidr_block = "10.0.0.0/16"

 tags = {
   Name = "${var.name}-vpc"
 }
}

# adjust NACL
resource "aws_default_network_acl" "def_nacl" {
  default_network_acl_id = aws_vpc.app_vpc.default_network_acl_id

  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "${data.external.myipaddr.result.ip}/32"
    from_port = 22
    to_port = 22
  }

  ingress {
    protocol = "tcp"
    rule_no = 110
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }

  ingress {
    protocol = "tcp"
    rule_no = 120
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port = 443
  }

  ingress {
    protocol = "tcp"
    rule_no = 130
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1025
    to_port = 65535
  }

  ingress {
    protocol = "tcp"
    rule_no = 140
    action = "allow"
    cidr_block = aws_vpc.app_vpc.cidr_block
    from_port = 27017
    to_port = 27017
  }

  egress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "${data.external.myipaddr.result.ip}/32"
    from_port = 22
    to_port = 22
  }

  egress {
    protocol = "tcp"
    rule_no = 110
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 1025
    to_port = 65535
  }

  egress {
    protocol = "tcp"
    rule_no = 120
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 80
    to_port = 80
  }

  egress {
    protocol = "tcp"
    rule_no = 130
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 443
    to_port = 443
  }

  egress {
    protocol = "tcp"
    rule_no = 140
    action = "allow"
    cidr_block = aws_vpc.app_vpc.cidr_block
    from_port = 27017
    to_port = 27017
  }

  egress {
    protocol = "tcp"
    rule_no = 150
    action = "allow"
    cidr_block = aws_vpc.app_vpc.cidr_block
    from_port = 22
    to_port = 22
  }
}

# create subnet inside devops vpc
resource "aws_subnet" "app_pub_subnet" {
  vpc_id = aws_vpc.app_vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1b"
}

# route tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app_gw.id
  }

  tags = {
    Name = "${var.name}-public-sub"
  }
}

resource "aws_route_table_association" "link_assoc" {
  subnet_id = aws_subnet.app_pub_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_internet_gateway" "app_gw" {
  vpc_id = aws_vpc.app_vpc.id
}

data "local_file" "my_pem" {
  filename = "/Users/kmonteiro/.ssh/kevin-eng54.pem"
}

# launch ec2
resource "aws_instance" "app_instance" {
  ami = "ami-05115c41c2088464f"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.app_pub_subnet.id
  security_groups = [aws_security_group.home_access.id]
  key_name = "kevin-eng54"

  tags = {
    Name = var.name
  }

  provisioner "remote-exec" {
    inline = [
      "sudo systemctl start nginx",
      "sudo unlink /etc/nginx/sites-enabled/default",
      "sudo cp /home/ubuntu/reverse-proxy.conf /etc/nginx/sites-available/reverse-proxy.conf",
      "ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf",
      "sudo systemctl reload-or-restart nginx",
      "cd /home/ubuntu/app",
      "sudo npm install",
      "npm start &"
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
      host = self.public_ip
      private_key = data.local_file.my_pem.content
    }
  }
}

resource "aws_security_group" "home_access" {
  name = "node-app-ports-km-eng54"
  description = "allows needed ports for node app"
  vpc_id = aws_vpc.app_vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =["${data.external.myipaddr.result.ip}/32"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-tags"
  }
}
