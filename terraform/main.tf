variable "key_name" {
  description = "How to name SSH keypair and security group in AWS."
}

variable "public_key_path" {
  description = "Enter the path to the SSH Public Key to add to AWS."
  default     = "~/.ssh/id_rsa.pub"
}

variable "create_key_pair" {
  description = "Should terraform create ssh-key"
  default     = true
}

variable "region" {
  type = "string"
}

variable "spot_price" {
  type        = "string"
  description = "The price to request on the spot market"
}

variable "ami_name" {
  type        = "string"
  description = "Name of ami to use"
  default     = "anaconda-4.4.0"
}

variable "ami_owner" {
  type        = "string"
  description = "Owner of ami"
  default     = "828328152120"
}

terraform {
  required_version = ">= 0.9.4"
}

provider "aws" {
  region = "${var.region}"
}

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

resource "aws_spot_instance_request" "anaconda" {
  ami                  = "${data.aws_ami.anaconda.id}"
  instance_type        = "r4.xlarge"
  spot_price           = "${var.spot_price}"
  wait_for_fulfillment = true
  spot_type            = "one-time"
  key_name             = "${format("%s-jupyter", var.key_name)}"

  vpc_security_group_ids = [
    "${aws_security_group.jupyter.id}",
  ]
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
