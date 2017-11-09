variable "public_key_path" {
  description = "Enter the path to the SSH Public Key to add to AWS."
  default     = "~/.ssh/id_rsa.pub"
}

variable "create_key_pair" {
  description = "Should terraform create ssh-key"
  default     = true
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

data "aws_ebs_volume" "ebs_data_volume" {
  most_recent = true

  filter {
    name   = "volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "tag:Name"
    values = ["${format("data-%s", var.key_name)}"]
  }
}

resource "aws_volume_attachment" "ebs_data_volume" {
  device_name  = "/dev/xvdv"
  volume_id    = "${data.aws_ebs_volume.ebs_data_volume.id}"
  instance_id  = "${aws_spot_instance_request.anaconda.spot_instance_id}"
  skip_destroy = true

  connection {
    host  = "${aws_spot_instance_request.anaconda.public_ip}"
    type  = "ssh"
    user  = "ubuntu"
    agent = "true"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/bootstrap",
      "sudo /tmp/bootstrap",
    ]
  }
}

resource "aws_spot_instance_request" "anaconda" {
  ami                  = "${data.aws_ami.anaconda.id}"
  instance_type        = "r4.4xlarge"
  spot_price           = "${var.spot_price}"
  availability_zone    = "${var.availability_zone}"
  wait_for_fulfillment = true
  spot_type            = "one-time"
  key_name             = "${format("%s-jupyter", var.key_name)}"

  vpc_security_group_ids = [
    "${aws_security_group.jupyter.id}",
  ]

  connection {
    type  = "ssh"
    user  = "ubuntu"
    agent = "true"
  }

  provisioner "file" {
    source      = "${path.module}/bootstrap"
    destination = "/tmp/bootstrap"
  }

  # Without this sometimes the error arises
  # E: Could not get lock /var/lib/dpkg/lock - open (11: Resource temporarily unavailable)
  provisioner "remote-exec" {
    inline = [
      "timeout 180 /bin/bash -x -c 'until stat /var/lib/cloud/instance/boot-finished &>/dev/null; do echo Waiting for cloud-init boot-finished; sleep 6; done'",
    ]
  }

  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "if grep -qs '/home/ubuntu/data' /proc/mounts; then sudo umount /dev/xvdv1; fi"
    ]
  }
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
