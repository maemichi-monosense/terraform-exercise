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
