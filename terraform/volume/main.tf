resource "aws_ebs_volume" "volume" {
  availability_zone = "${var.availability_zone}"
  type              = "gp2"
  size              = 500

  tags = {
    Name = "${format("data-%s", var.key_name)}"
  }
}

output "volume_id" {
  value = "${aws_ebs_volume.volume.id}"
}
