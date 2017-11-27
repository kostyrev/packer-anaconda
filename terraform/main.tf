data "aws_ami" "anaconda" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["${var.ami_name}"]
  }

  owners = ["${var.ami_owner}"]
}

data "aws_vpc" "vpc" {
  default = true
}

resource "aws_security_group" "jupyter" {
  name        = "${format("jupyter-%s", var.key_name)}"
  description = "Allow ssh"
  vpc_id      = "${data.aws_vpc.vpc.id}"

  # Allow echo-requests
  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name   = "${format("%s-jupyter", var.key_name)}"
  public_key = "${file(var.public_key_path)}"
  count      = "${var.create_key_pair}"
}

output "public_dns" {
  value = ["${aws_spot_instance_request.anaconda.public_dns}"]
}

output "public_address" {
  value = ["${aws_spot_instance_request.anaconda.public_ip}"]
}

output "instance_type" {
  value = ["${aws_spot_instance_request.anaconda.instance_type}"]
}
