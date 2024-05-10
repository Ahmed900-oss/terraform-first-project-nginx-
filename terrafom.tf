provider "aws" {
  region              = "us-east-1"
  shared_config_files = ["C:/Users/Ahmed/.aws/credentials"]
}
variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
#create vpc
resource "aws_vpc" "app-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name : "${var.env_prefix}-vpc"
  }
}
#create subnet
resource "aws_subnet" "vpc-subnet-1" {
  vpc_id            = aws_vpc.app-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name : "${var.env_prefix}-subnet-1"
  }
}
#create internet gateway
resource "aws_internet_gateway" "app-internet-gateway" {
  vpc_id = aws_vpc.app-vpc.id
  tags = {
    Name : "${var.env_prefix}-internet-gatway"
  }
}
/*#create route table based on internet-gateway
resource "aws_route_table" "app-route-table" {
  vpc_id = aws_vpc.app-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app-internet-gateway.id
  }
  tags = {
    Name = "${var.env_prefix}-route-table"
  }
}
# rtb_association connect the route table with specific subnet
resource "aws_route_table_association" "app-rtb-association" {
  subnet_id      = aws_subnet.vpc-subnet-1.id
  route_table_id = aws_route_table.app-route-table.id
}*/


# another way --> use the default routetable

resource "aws_default_route_table" "app-default-rtb" {
  default_route_table_id = aws_vpc.app-vpc.default_route_table_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.app-internet-gateway.id
  }
  tags = {
    Name : "${var.env_prefix}-main-rtb"
  }
}

/*#create a security group (firewall)

resource "aws_security_group" "app-security-group" {
  name   = "app-firewall"
  vpc_id = aws_vpc.app-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name : "${var.env_prefix}-sg"
  }
}*/

resource "aws_default_security_group" "app-default-security-group" {
  vpc_id = aws_vpc.app-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
  tags = {
    Name : "${var.env_prefix}-default-sg"
  }
}

data "aws_ami" "amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
output "aws_ami_id" {
  value = data.aws_ami.amazon-linux-image.id
}
resource "aws_instance" "app-server" {
  ami           = data.aws_ami.amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id                   = aws_subnet.vpc-subnet-1.id
  vpc_security_group_ids      = [aws_default_security_group.app-default-security-group.id]
  availability_zone           = var.avail_zone
  associate_public_ip_address = true
  key_name                    = "keypair"
  user_data                   = file("script.sh")

  tags = {
    Name = "${var.env_prefix}-app-server"
  }
}
output "ec2_ip" {
  value = aws_instance.app-server.public_ip
}
