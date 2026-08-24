resource "null_resource" "server" {
  triggers = {
    ip   = var.vm_ip
    name = var.name
  }

}