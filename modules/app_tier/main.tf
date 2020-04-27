# create internet gateway
resource "aws_internet_gateway" "app_gw" {
  vpc_id = var.vpc_id
}

# adjust NACL
resource "aws_default_network_acl" "def_nacl" {
  default_network_acl_id = var.def_nacl
  subnet_ids = [aws_subnet.app_pub_subnet.id]

  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "${var.my_ip}/32"
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
    cidr_block = var.vpc_cb
    from_port = 27017
    to_port = 27017
  }

  egress {
    protocol = "tcp"
    rule_no = 100
    action = "allow"
    cidr_block = "${var.my_ip}/32"
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
    cidr_block = var.vpc_cb
    from_port = 27017
    to_port = 27017
  }

  egress {
    protocol = "tcp"
    rule_no = 150
    action = "allow"
    cidr_block = var.vpc_cb
    from_port = 22
    to_port = 22
  }
}

# create subnet inside devops vpc
resource "aws_subnet" "app_pub_subnet" {
  vpc_id = var.vpc_id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1b"
}

# route tables
resource "aws_route_table" "public_rt" {
  vpc_id = var.vpc_id

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

data "template_file" "app_provs" {
  template = file("./templates/app/provision.sh.tpl")

  vars = {
    db_priv_ip = var.db_ip
  }
}

# launch ec2
resource "aws_instance" "app_instance" {
  ami = var.ami_id
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.app_pub_subnet.id
  security_groups = [aws_security_group.home_access.id]
  key_name = "kevin-eng54"
  user_data = data.template_file.app_provs.rendered

  tags = {
    Name = "${var.name}"
  }
}

resource "aws_security_group" "home_access" {
  name = "node-app-ports-km-eng54"
  description = "allows needed ports for node app"
  vpc_id = var.vpc_id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =["10.0.2.0/24"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =["${var.my_ip}/32"]
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
    from_port = 1025
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }

  tags = {
    Name = "${var.name}-tags"
  }
}
