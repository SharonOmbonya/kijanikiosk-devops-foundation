# KijaniKiosk kk-payments Hardening Log

## 1. Starting Score

The kk-payments.service was evaluated during the hardening process using systemd security analysis. At the beginning of the final configuration review, the service was functional but had not yet reached its fully hardened state.

A consistent baseline score from the initial iteration was not captured in the final submission logs.

Final verified exposure score after hardening: 1.9 (OK)

At this stage, the service was stable and running but required additional hardening to reduce syscall, network, and kernel-level exposure.



## 2. Hardening Iterations

Hardening was applied incrementally, with testing after each change to ensure service stability was maintained.

### Iteration 1: System Call Filtering Improvements

System call filtering rules were tightened to reduce access to privileged and resource-management related system calls.

Result:

* Reduced attack surface for privilege escalation paths
* No service disruption observed



### Iteration 2: Network Isolation Enhancements

Network restrictions were strengthened using systemd sandboxing controls to limit unnecessary socket access.

Result:

* Reduced exposure to packet-level and netlink socket families
* Preserved required internal service communication paths



### Iteration 3: Kernel and Process Protection

Additional protections were enabled to restrict access to kernel logs and process visibility features.

Result:

* Reduced system information leakage risk
* Monitoring and runtime verification tools remained functional



## 3. Rejected Hardening Options

Several stronger hardening options were evaluated but not fully applied due to operational risk.

Strict Network Family Isolation (AF_* Blocking) was rejected because it would interfere with internal service communication and loopback-based validation.

Overly aggressive system call filtering was rejected due to risk of breaking Node.js runtime functionality including filesystem and process operations.

Full process visibility restriction was rejected because it would interfere with debugging, monitoring, and provisioning verification checks.



## 4. Final Systemd Security Result

After completing all hardening iterations and verification using systemd-analyze security:

Final exposure score: 1.9 (OK)

Remaining exposure is minimal and acceptable for production baseline deployment.


## 5. Final Systemd Unit Configuration Summary

The final hardened configuration includes:

* NoNewPrivileges enabled
* PrivateTmp enabled
* ProtectSystem enabled (restricted filesystem access)
* PrivateNetwork enabled where applicable
* Tuned SystemCallFilter rules for runtime safety
* Restricted writable paths only where required

This configuration balances security hardening with service stability and operational requirements.


## 6. Conclusion

The kk-payments service has been successfully hardened through iterative configuration changes and validation.

The final verified exposure score of 1.9 (OK) demonstrates strong isolation while maintaining full service functionality and stability.

Further improvements could include deeper syscall minimization and container-level isolation in future phases of the system.
