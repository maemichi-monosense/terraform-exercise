output "public ip of bastion" {
  value = "${aws_instance.bastion.public_ip}"
}
