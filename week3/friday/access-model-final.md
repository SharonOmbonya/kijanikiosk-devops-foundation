# KijaniKiosk Access Model (Final)

## Overview

KijaniKiosk uses a role-based access control model built around dedicated service accounts, controlled group membership, and Access Control Lists (ACLs). The objective is to ensure that each service has only the permissions required for its role while allowing limited and controlled sharing of operational resources.

The model follows the principle of least privilege and was designed to remain functional after repeated provisioning runs, log rotation events, and service restarts.

---

## Service Accounts

### kk-api

Purpose:

* Runs the API service.

Directory Ownership:

* Owns `/opt/kijanikiosk/api`

Permissions:

* Full control of API resources.
* Read and execute access to the shared logging directory through ACLs.
* Member of the `kijanikiosk` group.

Restrictions:

* No ownership of payment resources.
* Cannot modify configuration files.

---

### kk-payments

Purpose:

* Runs the payment processing service.

Directory Ownership:

* Owns `/opt/kijanikiosk/payments`

Permissions:

* Full control of payment resources.
* Read and execute access to the shared logging directory for audit and troubleshooting purposes.
* Member of the `kijanikiosk` group.

Restrictions:

* Cannot modify shared logs.
* Cannot modify configuration files.



### kk-logs

Purpose:

* Manages centralized logging.

Directory Ownership:

* Owns `/opt/kijanikiosk/logs`
* Owns the shared logging infrastructure.

Permissions:

* Full read, write, and execute access to shared logs.
* Owns health-check output files generated during provisioning.

Responsibilities:

* Log aggregation.
* Log maintenance.
* Log rotation support.



## Shared Group

### kijanikiosk

The `kijanikiosk` group provides controlled visibility across services without granting unrestricted access.

Members:

* kk-api
* kk-payments
* kk-logs

The group is used primarily for:

* Shared configuration visibility.
* Monitoring access.
* Health reporting visibility.
* Controlled cross-service access.



## Directory Access Model

### /opt/kijanikiosk/api

Owner:

* kk-api:kk-api

Permissions:

* 750

Purpose:

* Stores API service resources.



### /opt/kijanikiosk/payments

Owner:

* kk-payments:kk-payments

Permissions:

* 750

Purpose:

* Stores payment service resources.

### /opt/kijanikiosk/logs

Owner:

* kk-logs:kk-logs

Permissions:

* 750

Purpose:

* Stores logging service resources.



### /opt/kijanikiosk/config

Owner:

* root:kijanikiosk

Permissions:

* 750

Purpose:

* Stores service configuration files.

Access Model:

* Administrative ownership remains with root.
* Group members may read configuration where required.
* Service accounts cannot modify configuration.

This protects configuration integrity while allowing controlled access.



### /opt/kijanikiosk/health

Owner:

* root:kijanikiosk

Permissions:

* 750

Purpose:

* Stores provisioning and monitoring health information.

Health Status File:

* `last-provision.json`

Ownership:

* kk-logs:kijanikiosk

Permissions:

* 640

Access Model:

* Provisioning writes health results.
* Monitoring systems can read status information.
* Unauthorized modification is prevented through controlled ownership.

This directory was added during the production foundation phase to support structured monitoring and verification.



### /opt/kijanikiosk/shared/logs

Owner:

* kk-logs:kijanikiosk

Permissions:

* 2770 (setgid enabled)

Purpose:

* Centralized logging location shared across services.

ACL Permissions:

| User        | Access |
| ----------- | ------ |
| kk-logs     | rwx    |
| kk-api      | rwx    |
| kk-payments | r-x    |

Default ACLs are configured so new files inherit the same access model automatically.

## ACL and Inheritance Design

The shared logging directory uses ACLs to provide fine-grained access control.

Configured Default ACLs:

* kk-logs → rwx
* kk-api → r-x
* kk-payments → r-x

The directory also uses the setgid bit (`2770`), ensuring that newly created files inherit the correct group ownership.

This approach allows controlled sharing without granting excessive permissions.



## Logrotate Interaction

Log rotation creates new log files after existing logs are archived.

Without ACL inheritance, newly created log files could lose the permissions required by the KijaniKiosk services.

To prevent this:

* The shared logs directory is configured with default ACLs.
* The directory uses setgid inheritance.
* Logrotate creates replacement files using controlled ownership and permissions.
* New files automatically inherit the required ACL entries.

This ensures that service access remains consistent after log rotation and prevents operational failures caused by permission changes.



## Security Principles

The access model is based on the following principles:

1. Least privilege.
2. Dedicated service identities.
3. Separation of service resources.
4. Controlled cross-service access.
5. Root ownership of critical configuration.
6. ACL-based permission management.
7. Persistent permission inheritance.
8. Consistent access after log rotation.

These controls provide a secure and maintainable foundation for KijaniKiosk production services while supporting operational requirements such as monitoring, logging, and repeatable provisioning.

