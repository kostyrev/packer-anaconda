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

  root_block_device {
    volume_size = "${var.root_volume_size}"
  }

  connection {
    type  = "ssh"
    user  = "ubuntu"
    agent = "true"
  }

  provisioner "file" {
    source      = "${path.module}/bootstrap"
    destination = "/tmp/bootstrap"
  }

  provisioner "remote-exec" {
    when = "destroy"

    inline = [
      "if grep -qs '/home/ubuntu/data' /proc/mounts; then sudo umount /dev/xvdv1; fi",
    ]
  }
}
