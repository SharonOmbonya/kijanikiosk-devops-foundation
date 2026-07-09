variable "servers" {
  description = "KijaniKiosk server definitions"
  type = map(object({
    name = string
  }))
}

variable "environment" {
  description = "Deployment environment (staging/production)"
  type        = string
  default     = "staging"
}

variable "instance_type" {
  description = "VM instance type for all servers"
  type        = string
  default     = "t2.micro"
}

variable "ssh_key_path" {
  description = "Path to SSH private key used for provisioning"
  type        = string
}

variable "vm_name_prefix" {
  description = "Multipass VM name prefix"
  type        = string
  default     = "kijanikiosk"
}