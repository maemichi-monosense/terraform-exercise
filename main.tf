variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
  default = "ap-northeast-1"
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region     = "${var.region}"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.1.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "false"
  tags {
    Name = "terraform-main"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main.id}"
}

variable "n-public" {
  default = 0x0
}
variable "n-private" {
  default = 0x80
}
variable "n-a" {
  default = 0x0
}
variable "n-c" {
  default = 0x40
}

resource "aws_subnet" "public-a" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "10.1.${var.n-public + var.n-a}.0/20"
  availability_zone = "${var.region}a"

  map_public_ip_on_launch = true
}

resource "aws_subnet" "public-c" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "10.1.${var.n-public + var.n-c}.0/20"
  availability_zone = "${var.region}c"

  map_public_ip_on_launch = true
}

resource "aws_subnet" "private-a" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "10.1.${var.n-private + var.n-a}.0/20"
  availability_zone = "${var.region}a"
}

resource "aws_subnet" "private-c" {
  vpc_id            = "${aws_vpc.main.id}"
  cidr_block        = "10.1.${var.n-private + var.n-c}.0/20"
  availability_zone = "${var.region}c"
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.private-a.id}"
  depends_on    = ["aws_internet_gateway.igw"]
}

resource "aws_route_table" "public-route" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
}

resource "aws_route_table" "private-route" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.ngw.id}"
  }
}

resource "aws_route_table_association" "puclic-a" {
  subnet_id = "${aws_subnet.public-a.id}"
  route_table_id = "${aws_route_table.public-route.id}"
}

resource "aws_route_table_association" "puclic-c" {
  subnet_id = "${aws_subnet.public-c.id}"
  route_table_id = "${aws_route_table.public-route.id}"
}

resource "aws_route_table_association" "private-a" {
  subnet_id = "${aws_subnet.private-a.id}"
  route_table_id = "${aws_route_table.private-route.id}"
}

resource "aws_route_table_association" "private-c" {
  subnet_id = "${aws_subnet.private-c.id}"
  route_table_id = "${aws_route_table.private-route.id}"
}

resource "aws_security_group" "main" {
  name = "terraform-main"
  description = "Allow all inbound traffic"
  tags { Name = "terraform-main" }
  vpc_id = "${aws_vpc.main.id}"
  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "admin" {
  name = "terraform-admin"
  description = "Allow SSH inbound traffic"
  tags { Name = "terraform-admin" }
  vpc_id = "${aws_vpc.main.id}"
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "ami_id" {
  default = "ami-b80b6db8" // CentOS 7 x86_64 (2014_09_29) EBS
}

resource "aws_instance" "bastion" {
  ami = "${var.ami_id}"
  instance_type = "t2.micro"
  key_name = "terraform.monosense"
  vpc_security_group_ids = [
    "${aws_security_group.main.id}"
    , "${aws_security_group.admin.id}"
  ]
  subnet_id = "${aws_subnet.public-a.id}"
  associate_public_ip_address = true
  root_block_device = {
    volume_type = "gp2"
    delete_on_termination = true
  }
  tags {
    Name = "terraform-bastion"
  }
  user_data = <<EOS
    #cloud-config
    hostname: "bastion"
    timezone: "Asia/Tokyo"
EOS
}

resource "aws_instance" "server" {
  ami = "${var.ami_id}"
  instance_type = "t2.micro"
  key_name = "terraform.monosense"
  vpc_security_group_ids = [
    "${aws_security_group.main.id}"
  ]
  subnet_id = "${aws_subnet.private-a.id}"
  associate_public_ip_address = false
  root_block_device = {
    volume_type = "gp2"
    delete_on_termination = true
  }
  tags {
    Name = "terraform-server"
  }
  user_data = <<EOS
    #cloud-config
    hostname: "server"
    timezone: "Asia/Tokyo"
EOS
}

output "public ip of bastion" {
  value = "${aws_instance.bastion.public_ip}"
}
