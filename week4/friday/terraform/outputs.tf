output "api_server_ip" {
  value = module.app_servers["api"].ip
}

output "payments_server_ip" {
  value = module.app_servers["payments"].ip
}

output "logs_server_ip" {
  value = module.app_servers["logs"].ip
}

output "ssh_commands" {
  value = {
    api      = "ssh ubuntu@${module.app_servers["api"].ip}"
    payments = "ssh ubuntu@${module.app_servers["payments"].ip}"
    logs     = "ssh ubuntu@${module.app_servers["logs"].ip}"
  }
}