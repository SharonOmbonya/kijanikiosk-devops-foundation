KIJANIKIOSK PRODUCTION FOUNDATION - HARDENING DECISIONS

1. INTRODUCTION

This document explains the security design decisions applied to the KijaniKiosk production foundation. It is written for non-technical stakeholders and focuses on risk reduction, operational trade-offs, and system reliability rather than implementation details.

The goal of the system is to ensure services run reliably while maintaining a secure and controlled environment suitable for early production deployment.

2. OVERALL SECURITY APPROACH

The system was designed with a balanced approach between security and operational stability. Instead of applying maximum isolation immediately, security improvements were introduced gradually to ensure that all services remain functional.

This approach ensures that critical services such as payments, logging, and API processing are not disrupted by overly restrictive configurations.

3. SECURITY CONTROLS IMPLEMENTED

Control | What it does | Risk mitigated
--------|-------------|----------------
Dedicated service users | Each service runs under its own identity | Prevents cross-service access and limits damage if one service is compromised
Directory separation | Isolates api, logs, config, and health data into separate locations | Reduces accidental data exposure and prevents services overwriting each other’s files
ACL permissions | Fine-grained access control for shared files | Prevents over-permissioning and ensures only required services can access sensitive data
Group-based access | Shared controlled access layer between authorized services | Limits unrestricted privilege sharing while allowing necessary collaboration
Root-owned configuration | Protects system configuration files from modification by services | Prevents unauthorized or accidental system-level changes
Shared logging structure | Central logging system with controlled access and rotation policies | Preserves audit integrity and ensures logs remain available for troubleshooting
Service isolation | Each service runs independently with separated runtime context | Reduces blast radius of failures or compromises affecting other services
Health check logging | Tracks system status in structured and machine-readable form | Improves monitoring, early failure detection, and operational visibility
Controlled configuration access | Restricts who can read or modify sensitive configuration files | Prevents exposure or tampering with sensitive system settings

4. SECURITY OBSERVATIONS (FROM SYSTEM ANALYSIS)

System analysis of the payment service shows that it runs under a non-root identity, which is a strong baseline security control.

However, additional isolation features such as full sandboxing, capability restriction, and filesystem isolation are not fully applied. These represent potential areas for improvement but are not enabled to preserve system stability.

5. DESIGN TRADE-OFFS

Stronger security controls were evaluated but not fully applied due to operational risk.

In particular, stricter isolation mechanisms may interfere with the correct execution of payment processing and supporting services. Since correctness and reliability are critical for financial operations, the system prioritizes stable execution over aggressive lockdown.

This ensures that services remain available and functional in a real-world production environment.

6. LIMITATIONS AND FUTURE IMPROVEMENTS

The current system does not fully isolate services from the underlying operating system. Some system-level capabilities remain available, and full sandboxing is not enabled.

These limitations are intentional at this stage to ensure stability, but they represent clear areas for future hardening as the system matures.

7. CONCLUSION

The KijaniKiosk production foundation adopts a practical security posture that balances protection and usability. Services are isolated through users, groups, and access controls while maintaining enough flexibility for reliable operation.

This approach ensures the system is safe for early production use and provides a clear path for future security enhancements without disrupting service stability.
