module "app_servers" {
  source   = "./modules/app_server"
  for_each = local.servers

  name          = each.key
  environment   = var.environment
  instance_type = var.instance_type
  vm_ip         = each.value.ip
  ssh_key_path = var.ssh_key_path
  
  }