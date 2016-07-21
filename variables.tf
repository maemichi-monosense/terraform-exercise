variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {
  default = "ap-northeast-1"
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
variable "ami_id" {
  # Amazon Linux AMI 2016.03.3 (HVM), SSD Volume Type
  default = "ami-374db956"
}
