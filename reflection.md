# Reflection

## 1. Demo script and communicating reliability

The demo script explains the deployment process in simple language for a non-technical audience. One moment where the wording could feel like it is overclaiming is the statement that the release process can protect service availability. The evidence shows that the system can detect a failed release and automatically restore the previous working version, but this protection applies to the failure scenarios covered by the monitoring and rollback process.

A more precise explanation would be that the system reduces the impact of failed releases by detecting deployment problems and returning customers to a known healthy version quickly. This keeps the explanation understandable for the board while being accurate about the limits of the solution.

---

## 2. Highest-value post-incident action item

The highest-value action item I identified is adding automatic environment validation before allowing deployments to proceed. This directly addresses the root cause because the incident happened when a deployment was applied to the wrong environment due to an incorrect environment selection.

I am confident this change would greatly reduce the chance of the same type of incident happening again because it removes dependence on manually selecting the deployment target and introduces a verification step before changes are applied. However, this control would mainly prevent environment selection mistakes; it would not prevent every possible deployment failure, such as application defects or incorrect configuration values.

To be certain that this solution would work correctly, I would need more information about the current deployment pipeline implementation. Specifically, I would need to understand how environments are selected, where deployment variables are stored, what checks currently run before deployment, and how permissions are managed between environments. This information would help determine where the validation should be placed and whether additional protections are required.

---

## 3. Blue/green and Kubernetes concepts

The main concept that carries from the blue/green deployment approach into Kubernetes is the need for controlled releases and a reliable way to return to a healthy version when a deployment fails. Health monitoring, validating a new version before exposing customers to it, and keeping a known working version available are important practices in both approaches.

The idea behind the state files also carries forward conceptually because a deployment system still needs to know which version is currently serving traffic and which version can be restored. However, Kubernetes manages the desired application state internally, so manually maintaining environment state files becomes less necessary.

The switch script and rollback script become less important because Kubernetes provides built-in mechanisms for managing application versions, replacing unhealthy instances, and returning to previous versions. Instead of manually changing traffic destinations and running recovery scripts, Kubernetes controllers continuously work to keep the application matching the defined deployment state.

The monitoring concept still remains important. Kubernetes can detect unhealthy application instances and replace them, but it does not understand every business-level failure automatically. Application health checks and monitoring are still required to determine whether a release is behaving correctly.

Overall, Kubernetes reduces the amount of manual recovery work required, but the principles behind safe deployment, health validation, and controlled rollback remain necessary.

---

## 4. Hardcoded values in the Kubernetes deployment manifest

Looking at the `kk-payments` deployment manifest, the main values that should come from configuration are the application runtime settings, deployment version, scaling settings, and resource requirements. The reason for separating these values is that the deployment definition should remain reusable while environment-specific settings can change without modifying the application deployment.

The environment variables `NODE_ENV: "production"` and `PORT: "3001"` are examples of values that should come from configuration. These values describe how the application should run rather than the application itself. If they remain hardcoded, the same deployment cannot easily be reused across development, testing, and production environments. Any change requires editing the manifest and redeploying, which increases the chance of configuration errors.

The container image version `sharonshaz/kk-payments:1.0.0-7a2b335` is also hardcoded. Application versions change during releases, so this value should be controlled by the deployment process. If it stays hardcoded, every release requires a manual manifest update, which can make deployments less reliable and increase the risk of running the wrong version.

The replica count `replicas: 2` should also be treated as configurable because the number of application instances depends on the environment and workload. A production environment may require more replicas than a development environment. Keeping this value fixed reduces flexibility and makes scaling changes dependent on manual updates.

The CPU and memory requests and limits are also hardcoded. These values should be adjustable because resource requirements change as the application workload changes. If they remain fixed, the application may not receive enough resources during higher demand, or resources may be reserved unnecessarily.

The manifest does not currently contain database credentials, payment provider keys, passwords, or other sensitive values. If those values were added in the future, they should be stored using Kubernetes Secrets rather than directly in the Deployment manifest.

The main operational problem with hardcoded values is that they make deployments harder to adapt and maintain. Moving environment-specific settings into configuration allows the same application deployment to be used more safely across different environments while reducing manual changes and deployment errors.
