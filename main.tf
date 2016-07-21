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

resource "aws_vpc" "My_VPC" {
  cidr_block           = "10.1.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "false"
  tags {
    Name = "My_VPC"
  }
}

resource "aws_internet_gateway" "My_GW" {
  vpc_id = "${aws_vpc.My_VPC.id}"
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
  vpc_id            = "${aws_vpc.My_VPC.id}"
  cidr_block        = "10.1.${var.n-public + var.n-a}.0/20"
  availability_zone = "${var.region}a"
}

resource "aws_subnet" "public-c" {
  vpc_id            = "${aws_vpc.My_VPC.id}"
  cidr_block        = "10.1.${var.n-public + var.n-c}.0/20"
  availability_zone = "${var.region}c"
}

resource "aws_subnet" "private-a" {
  vpc_id            = "${aws_vpc.My_VPC.id}"
  cidr_block        = "10.1.${var.n-private + var.n-a}.0/20"
  availability_zone = "${var.region}a"
}

resource "aws_subnet" "private-c" {
  vpc_id            = "${aws_vpc.My_VPC.id}"
  cidr_block        = "10.1.${var.n-private + var.n-c}.0/20"
  availability_zone = "${var.region}c"
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "ngw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.private-a.id}"
  depends_on    = ["aws_internet_gateway.My_GW"]
}

resource "aws_route_table" "public-route" {
  vpc_id = "${aws_vpc.My_VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.My_GW.id}"
  }
}

resource "aws_route_table" "private-route" {
  vpc_id = "${aws_vpc.My_VPC.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.ngw.id}"
  }
}
