# create subnet inside devops vpc
resource "aws_subnet" "priv_subnet" {
  vpc_id = var.vpc_id
  cidr_block = "10.0.2.0/24"
  availability_zone = "eu-west-1b"
}

# create private NACL
resource "aws_network_acl" "priv_nacl" {
 vpc_id = var.vpc_id
 subnet_ids = [aws_subnet.priv_subnet.id]

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

# route tables
resource "aws_route_table" "private_rt" {
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.name}-private-sub"
  }
}

resource "aws_route_table_association" "link_assoc" {
  subnet_id = aws_subnet.priv_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# launch ec2
resource "aws_instance" "app_instance" {
  ami = var.ami_id
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.priv_subnet.id
  security_groups = [aws_security_group.db_access.id]
  key_name = "kevin-eng54"

  tags = {
    Name = "${var.name}"
  }
}

output "instance_ip_addr" {
  value = aws_instance.app_instance.private_ip
}

resource "aws_security_group" "db_access" {
  name = "node-db-ports-km-eng54"
  description = "allows needed ports for node app"
  vpc_id = var.vpc_id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =["${var.my_ip}/32"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  ingress {
    from_port = 1025
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  tags = {
    Name = "${var.name}-tags"
  }
}
