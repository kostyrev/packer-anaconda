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
