variable "name" {
  description = "Server role: api, payments, logs"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "instance_type" {
  description = "VM size"
  type        = string
}

variable "vm_ip" {
  description = "Multipass VM IP address"
  type        = string
}

variable "ssh_key_path" {
  description = "Path to SSH private key"
  type        = string
}