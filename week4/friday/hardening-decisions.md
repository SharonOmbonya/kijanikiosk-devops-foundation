
# KijaniKiosk Hardening Decisions

## Security Approach

The KijaniKiosk staging environment was designed around the principle that infrastructure should be repeatable, reviewable, and secure by default. The goal was not only to create working servers, but to create an environment where security decisions are documented and can be explained clearly to the board.

The infrastructure creation process uses Terraform so that server requirements are recorded as code rather than depending on manual setup. This reduces the risk of different environments being created with different security settings. Ansible then applies the required server configuration consistently across all systems, ensuring that security controls are reproduced every time.

Terraform state management was designed to support team visibility and reduce accidental changes. The project uses MinIO as the remote state storage solution. A known limitation is that this storage approach does not provide native state locking in the same way some production cloud platforms do. In a production environment, additional controls would be introduced, such as DynamoDB locking with AWS, built-in locking with Google Cloud Storage, or Consul for a vendor-neutral approach.

Access management was also considered during the infrastructure design. Server access is controlled through managed key pairs rather than shared passwords. This reduces the risk of unauthorized access and provides a clearer method for managing who can connect to the environment.

The payment service received additional protection through system-level security controls. The kk-payments service achieved a systemd security score of 1.9, which is below the required threshold of 2.5. These controls reduce the impact of a potential compromise by limiting what the service can access and modify.

## Security Controls

| Control | What it does | Risk mitigated |
|---|---|---|
| Remote state storage | Keeps infrastructure information in a shared and controlled location instead of relying on one engineer’s machine | Reduces the risk of lost state, conflicting changes, and undocumented infrastructure |
| State locking approach | Production environments can use dedicated state locking mechanisms to prevent multiple engineers from changing infrastructure at the same time | Reduces accidental infrastructure conflicts and unexpected deployments |
| Security group restrictions | Limits which network connections can reach the servers | Reduces exposure to unauthorized access attempts |
| Key pair management | Uses controlled authentication keys instead of shared passwords for server access | Reduces the risk of unauthorized account access |
| Terraform variables | Separates environment-specific information from infrastructure definitions | Reduces configuration mistakes when creating new environments |
| NoNewPrivileges protection | Prevents the service from gaining additional privileges after startup | Limits damage if the application is compromised |
| ProtectSystem protection | Prevents the service from changing important operating system areas | Reduces the risk of system modification by an exploited application |
| PrivateDevices protection | Restricts access to unnecessary system devices | Reduces exposure to hardware-related resources |
| Capability restrictions | Removes unnecessary permissions from the service | Limits privilege escalation opportunities |
| System call filtering | Reduces the number of operating system actions available to the service | Decreases the possible attack surface available to attackers |

## Security Trade-offs and Decisions

Security improvements always require balancing protection with application requirements. The payment service needs network access because it communicates with other components, so restrictions were applied while allowing required application behaviour. Similarly, stronger filesystem protection was enabled while ensuring the service could still access the resources it needs to operate correctly.

One important challenge was ensuring that security controls did not prevent normal service operation. Strong filesystem protection can restrict applications from accessing required configuration information. The final design placed necessary service resources in approved locations while keeping the wider system protected from unnecessary changes.

The use of infrastructure as code also improves accountability. Every security decision is stored alongside the environment definition, allowing another engineer to understand why a control exists rather than relying on personal knowledge. This supports the goal of creating a staging environment that can be reproduced consistently.

The current design also demonstrates that security is not only about preventing access. It is also about reducing the possible impact when something goes wrong. By limiting permissions, controlling access paths, and documenting decisions, the environment becomes easier to maintain and safer to operate.

These decisions also improve operational confidence since future engineers can review the environment design and understand the reason behind each protection.

## Current Security Limitations

The current security posture significantly reduces common infrastructure risks, but it does not protect against every possible threat. It does not prevent application-level vulnerabilities inside the KijaniKiosk code itself, stolen user credentials, malicious actions by trusted users, or weaknesses caused by incorrect business logic. Future improvements should include application security testing, stronger monitoring, automated vulnerability scanning, and additional production access controls. The current environment provides a strong foundation, but security requires continuous review as the system and its risks change.

