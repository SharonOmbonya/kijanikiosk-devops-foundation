# KijaniKiosk Integration Notes

## 1. Service Hardening vs Service Functionality

The KijaniKiosk services required security hardening while still remaining functional. The challenge was applying service isolation and security controls without preventing the services from starting or accessing the resources they require.

Several options were considered. One option was to apply very restrictive security settings immediately. Another option was to apply only the controls that could be verified to work correctly with the service configuration.

The chosen solution was to balance security and functionality by applying hardening measures while ensuring that service accounts retained access to their required directories and resources.

This approach improved security without introducing service failures.

## 2. Health Directory Access Design

The health directory is used to store service health information that may be accessed by multiple components. The challenge was allowing visibility while preventing unauthorized modification.

Several options were considered, including making the directory writable by all service accounts or restricting it entirely to root.

The chosen solution was to keep ownership controlled and use group-based access where appropriate. This provides visibility while limiting unnecessary write access.

This design supports monitoring requirements while protecting the integrity of health information.

## 3. Logrotate vs Service Isolation
Log files must be rotated regularly to prevent uncontrolled growth. However, log rotation can create permission and ownership issues that interfere with service access.

One option was to manually reset permissions after every rotation. Another option was to rely on ACLs so that permissions are preserved automatically.

The chosen solution was to use ACLs on the shared logging directory and configure default ACL inheritance. This ensures that service accounts retain the required access even after log rotation occurs.

This approach reduces administrative overhead and improves reliability.

## 4. Dirty VM vs Package State (Idempotency Handling)

The assignment required provisioning on a system that may already contain users, groups, directories, services, or other partial configuration.

One option was to assume a clean system and recreate all resources every time. This would cause failures when resources already existed. Another option was to check for existing resources before attempting creation.

The chosen solution was to implement idempotent provisioning behaviour. Existing users, groups, directories, and services are detected and handled safely rather than causing script failure.

This allows the provisioning script to be executed repeatedly while maintaining a consistent system state.

## Conclusion

The integration challenges were resolved by prioritizing security, reliability, and repeatability. Filesystem protection was maintained while preserving configuration access, health information remained protected while supporting monitoring, log rotation was integrated with ACL-based permissions, and provisioning was designed to operate safely on both clean and partially configured systems.

These decisions support a secure and maintainable KijaniKiosk deployment while satisfying the assignment requirements.






