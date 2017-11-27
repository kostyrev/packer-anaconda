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
