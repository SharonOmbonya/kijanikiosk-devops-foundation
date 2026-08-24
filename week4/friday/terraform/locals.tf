locals {
  servers = {
    api = {
      ip = data.external.api_ip.result.ip
    }
    payments = {
      ip = data.external.payments_ip.result.ip
    }
    logs = {
      ip = data.external.logs_ip.result.ip
    }
  }
}