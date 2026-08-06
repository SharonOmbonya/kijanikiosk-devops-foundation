# KijaniKiosk Deployment Approach Comparison

## Introduction

KijaniKiosk uses two different approaches to improve deployment reliability: a blue/green deployment model and a container-based Kubernetes model. Both approaches aim to reduce downtime and improve confidence when releasing changes, but they solve different operational challenges.

The blue/green approach focuses on controlling traffic movement between two application environments. It allows a new version to be prepared separately before users are moved to it. The container approach focuses on packaging the application consistently and allowing the platform to manage running application instances.

Both approaches improve safety, but they provide different advantages. Blue/green deployments provide a controlled release process, while containers provide a repeatable application environment with automated recovery capabilities.

## Deployment Comparison

| Concern              | Blue/green approach                                                                                                                                                                                                      | Container approach                                                                                                                                                                                                               |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Deployment mechanism | The application runs in two separate environments. A new version is deployed to the inactive environment, tested, and then traffic is switched when it is healthy.                                                       | The application is packaged as a container image and deployed as multiple running instances. The platform manages the application lifecycle after deployment.                                                                    |
| Rollback mechanism   | Rollback is performed by switching traffic back to the previous environment. During testing, the failed release was automatically replaced by returning traffic from the new environment to the previous stable version. | Rollback is handled by replacing the running application version with a previous container version. The platform can manage changes between application versions without manually moving traffic between environments.           |
| Failure recovery     | Recovery depends on detecting a failed release and switching traffic back to the stable environment. In testing, the automated rollback restored service in 15 seconds after the failed release was detected.            | Recovery focuses on maintaining healthy running instances. When an application instance is removed, the platform creates a replacement automatically. The recorded recovery time for replacing a failed instance was 71 seconds. |
| Scaling              | Scaling requires preparing additional environments or application capacity manually. It provides safe releases but requires additional planning when demand changes.                                                     | Scaling is based on running additional application instances when more capacity is required. Multiple instances can serve requests while the platform manages their availability.                                                |

## Evidence from the Implementation

The blue/green deployment process successfully moved customer traffic from the original environment to the new environment after confirming that the new release was healthy. The new version was verified as serving correctly before becoming active. When the new release was intentionally failed, the monitoring process detected the problem and automatically restored service to the previous stable version. The complete rollback process finished in 15 seconds, demonstrating that automated recovery can restore service faster than waiting for a manual response.

The container deployment demonstrated a different reliability model. The application was packaged into a production container image with a verified size of 44.9 MB, keeping the deployment lightweight while excluding unnecessary build tools. The Kubernetes deployment maintained two running application instances, providing availability even when one instance was removed. During testing, the platform automatically created a replacement instance and restored the expected running state within 71 seconds.

The two approaches therefore provide different types of protection. Blue/green deployment reduces the risk of releasing a faulty version by allowing traffic changes to be controlled. Containers and Kubernetes reduce operational effort by maintaining application instances and recovering from individual failures automatically.

## What the Container Approach Does Not Yet Solve

Although containers improve consistency and recovery, they do not automatically solve every production challenge. The container platform does not decide how application configuration should be managed across different environments, and it does not remove the need for secure handling of sensitive information. Additional practices are still required for monitoring, security controls, deployment policies, and operational decisions.

The next stage of Kubernetes adoption would add stronger configuration management, secret handling, and more advanced operational controls. Containers provide a reliable foundation, but successful production operation still requires clear processes, appropriate monitoring, and responsible management of application changes.

Blue/green deployments and container platforms are not competing solutions. They can work together. A production system can use containerized applications while still applying safe release strategies such as controlled traffic switching. Combining both approaches provides stronger reliability by protecting against failed releases while allowing automated recovery and efficient scaling.
