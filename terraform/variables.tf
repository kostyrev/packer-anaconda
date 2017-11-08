variable "region" {
  type = "string"
}

variable "availability_zone" {
  type        = "string"
  description = "The availability zone in which to create an instance"
}

variable "key_name" {
  description = "How to name SSH keypair and security group in AWS."
}
