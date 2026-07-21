# Reflection

## 1. At what point during the project did you discover that two requirements conflicted? Describe the conflict and what you learned from resolving it.

I discovered the conflict when I introduced the system hardening decisions, especially ProtectSystem=strict and other security controls. These changes improved the security posture and helped the kk-payments service achieve a security score of 1.9, which met the required target.

However, the stronger filesystem protection created a challenge because the service needed access to its environment configuration. Initially, the environment file configuration was not set up correctly. After correcting the environment file path, the security score changed and increased to 5.8, showing that improving one area of security can sometimes introduce new configuration challenges.

I responded by reviewing the service configuration and introducing additional security controls while ensuring that the application could still access the resources it required. The main lesson I learned was that security hardening cannot be applied as isolated changes. Each security decision needs to be tested together with application requirements to ensure the system remains both secure and functional.

## 2. The hardening decisions document is written for Nia. Rewrite one sentence from it in the technical language you would use if writing it for Tendo instead. What is lost and what is gained in the translation?

For Nia, I would write:

"Strong filesystem protection prevents the service from changing important parts of the system, reducing the impact of a compromised application."

For Tendo, I would write:

"ProtectSystem=strict creates a restricted filesystem environment where system locations are read-only, while approved writable locations are explicitly defined for application operation."

The technical version provides more implementation detail and is useful for an engineer maintaining or troubleshooting the system. However, it loses some simplicity because a non-technical audience may not immediately understand the security benefit. The Nia version focuses on the business risk being reduced, while the Tendo version focuses on the exact technical control being applied.

## 3. Looking at the full pipeline (Terraform plus Ansible plus pipeline.sh): what is the single most fragile handoff?

The most fragile handoff in the pipeline is the connection between Terraform infrastructure creation and Ansible configuration. Terraform creates the servers and provides the information required by Ansible, but small differences in the target environment can cause this process to fail.

One possible failure point is MinIO remote state storage because the pipeline depends on the state being available and preserved between runs. If the state is not retained correctly, Terraform cannot confirm the existing infrastructure state, which affects reproducibility.

Another possible issue is the connection between generated inventory information and server access. Incorrect authentication details, network restrictions, or configuration differences can prevent Ansible from successfully managing the servers.

To make this handoff more reliable in a production environment, I would need to understand the target environment's state management solution, authentication approach, network restrictions, and server access requirements. This information would allow the pipeline to be designed around the real production environment rather than assumptions from the test setup.
