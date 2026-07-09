data "external" "api_ip" {
  program = ["bash", "-c",
    "multipass info kijanikiosk-api --format json | python3 -c 'import sys,json; d=json.load(sys.stdin); print(json.dumps({\"ip\": d[\"info\"][\"kijanikiosk-api\"][\"ipv4\"][0]}))'"
  ]
}

data "external" "payments_ip" {
  program = ["bash", "-c",
    "multipass info kijanikiosk-payments --format json | python3 -c 'import sys,json; d=json.load(sys.stdin); print(json.dumps({\"ip\": d[\"info\"][\"kijanikiosk-payments\"][\"ipv4\"][0]}))'"
  ]
}

data "external" "logs_ip" {
  program = ["bash", "-c",
    "multipass info kijanikiosk-logs --format json | python3 -c 'import sys,json; d=json.load(sys.stdin); print(json.dumps({\"ip\": d[\"info\"][\"kijanikiosk-logs\"][\"ipv4\"][0]}))'"
  ]
}