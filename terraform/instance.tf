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
