# AI Governance Log

## Purpose

This document records the AI assistance and governance controls applied during the development of the KijaniKiosk DevOps workflow, including the CI/CD pipeline, Kubernetes deployment, infrastructure configuration, troubleshooting, and production approval process.

AI-generated suggestions were treated as development and troubleshooting assistance rather than authoritative instructions. Suggestions were reviewed, tested against the actual project environment, and modified or rejected where necessary before being applied.

The developer remained responsible for validating correctness, security, configuration, deployment behaviour, and production decisions.

---

# AI Governance: Six-Point Checklist

This checklist applies to any change generated or assisted by an AI tool before it is accepted into the project or used in production.


| # | Control | What to check | Common AI gap |
|---|---|---|---|
| 1 | Least privilege | Every IAM role, policy, and permission is scoped to the minimum required. No wildcard actions or resources without justification. | AI may default to broad permissions to make examples work. |
| 2 | Encryption at rest and in transit | Sensitive storage and data transfer must be appropriately protected. | AI-generated infrastructure may omit encryption configuration unless explicitly requested. |
| 3 | No hardcoded secrets | Credentials, API keys, passwords, and tokens are not committed to the repository. | AI may provide placeholder credentials or examples that could accidentally be committed. |
| 4 | Naming and configuration conventions | Resources and configuration follow the project's established naming and environment conventions. | AI may introduce generic names or assumptions from unrelated examples. |
| 5 | Auditability and logging | Deployment, approval, and operational changes produce an auditable record. | AI may focus on functionality and omit operational traceability. |
| 6 | Data classification and residency | Sensitive data is handled in the correct environment and region and is not unnecessarily exposed. | AI may make assumptions about infrastructure or data locations without understanding the actual environment. |

---

# Application of the Governance Checklist

## 1. Least Privilege

AI-generated IAM permissions and cloud configuration must be reviewed before deployment.

Permissions must be limited to the resources and actions required by the KijaniKiosk workflow.

Broad permissions or wildcard actions are not accepted without justification.

## 2. Encryption

Storage and data-transfer configuration must be reviewed to ensure that sensitive receipt and application data is protected at rest and in transit.

AI-generated infrastructure configuration must not be accepted solely because it is syntactically valid.

## 3. Secrets

No AWS credentials, API keys, passwords, tokens, Docker credentials, Nexus credentials, or other sensitive values should be hardcoded in the repository.

Sensitive configuration must use appropriate secure mechanisms such as Jenkins credentials, environment variables, or managed secret mechanisms.

The Jenkins pipeline uses credential references rather than embedding the actual credentials in the Jenkinsfile.

Examples include:

```text
nexus-credentials
dockerhub-credentials
```

## 4. Naming and Configuration

Resources and deployment configuration must follow the KijaniKiosk project conventions and distinguish between staging and production environments.

AI-generated configuration must be compared with the actual project structure before being accepted.

## 5. Auditability

The CI/CD process must provide an auditable record of:

* pipeline execution;
* build results;
* deployment stages;
* staging verification;
* production approval;
* approval reason; and
* production deployment.

The production deployment requires an explicit human approval before the pipeline can continue.

## 6. Data Residency and Environment Separation

AI-generated recommendations must be reviewed against the actual project environment.

Configuration intended for staging must not incorrectly assume production infrastructure, and production configuration must not introduce unintended dependencies on the staging environment.

---

# AI Governance Entry 1 — Jenkins Docker Agent Configuration

## 1. Date

2026-08-17

## 2. Tool Used

ChatGPT

## 3. Task Description

Troubleshoot the Jenkins Docker agent after the initial pipeline configuration could not access required Docker, Kubernetes, and Minikube resources.

The Jenkins agent initially used a basic Node.js Docker image and did not have the required permissions or host resources available inside the container.

## 4. What Was Provided to the AI

The Jenkinsfile, Jenkins errors, Docker agent configuration, and information about the host Docker, Kubernetes, and Minikube environment were provided to AI.

The initial agent configuration was:

```groovy
agent {
    docker {
        image 'node:18.20.8-bookworm'
        args '-v /tmp:/tmp'
    }
}
```

## 5. What the AI Produced

AI recommended modifying the Docker agent configuration so that the Jenkins container could access the required host resources.

The resulting configuration included:

```text
--group-add 1006
--network minikube
-v /var/run/docker.sock:/var/run/docker.sock
-v /tmp:/tmp
-v /home/sharon/.kube:/home/node/.kube:ro
-v /home/sharon/.minikube:/home/node/.minikube:ro
```

The final agent used:

```groovy
agent {
    docker {
        image 'kijanikiosk-jenkins-agent:node18-kubectl'
        args '--group-add 1006 --network minikube -v /var/run/docker.sock:/var/run/docker.sock -v /tmp:/tmp -v /home/sharon/.kube:/home/node/.kube:ro -v /home/sharon/.minikube:/home/node/.minikube:ro'
    }
}
```

## 6. What It Got Right

The AI correctly identified that the Jenkins Docker container did not automatically have access to the host Docker socket, Kubernetes configuration, or Minikube configuration.

The `--group-add 1006` configuration addressed the permission problem associated with accessing the Docker socket.

The volume mounts made the required Kubernetes and Minikube configuration available inside the Jenkins container.

The Minikube network configuration also allowed the Jenkins agent to communicate with the local Minikube environment.

## 7. What It Got Wrong

The initial troubleshooting did not completely account for the difference between paths on the Jenkins host and paths inside the Docker container.

The host used paths such as:

```text
/home/sharon/.kube
/home/sharon/.minikube
```

but the Jenkins container accessed the mounted resources through different paths.

Therefore, simply mounting the files was not sufficient. The paths referenced by the Kubernetes configuration also had to be validated inside the container.

## 8. What I Changed Before Applying the Output

I tested the proposed Docker configuration against the actual Jenkins environment.

I added the required group membership, Docker socket mount, Minikube network, and read-only Kubernetes/Minikube configuration mounts.

I then verified the paths from inside the Jenkins container rather than assuming that host paths would automatically work inside the container.

---

# AI Governance Entry 2 — Kubernetes and Minikube Kubeconfig Path

## 1. Date

2026-08-18

## 2. Tool Used

ChatGPT

## 3. Task Description

Resolve a Kubernetes deployment problem where Jenkins could access the kubeconfig file but the Minikube paths referenced inside that configuration were not valid from within the Jenkins Docker container.

## 4. What Was Provided to the AI

The Jenkins deployment commands, Kubernetes configuration, Minikube paths, Docker volume mounts, and deployment errors were provided to AI.

## 5. What the AI Produced

AI recommended creating a container-local copy of the kubeconfig, changing the host Minikube path to the path available inside the container, and explicitly setting the `KUBECONFIG` environment variable.

The implemented solution was:

```bash
cp /home/node/.kube/config /tmp/jenkins-kubeconfig

sed -i 's|/home/sharon/.minikube|/home/node/.minikube|g' /tmp/jenkins-kubeconfig

export KUBECONFIG=/tmp/jenkins-kubeconfig
```

This was used during the staging and production deployment steps.

## 6. What It Got Right

The AI correctly identified that the kubeconfig contained a host-specific Minikube path.

The Jenkins container could see the mounted Minikube directory as:

```text
/home/node/.minikube
```

rather than:

```text
/home/sharon/.minikube
```

Copying the configuration, replacing the path, and explicitly setting `KUBECONFIG` allowed `kubectl` to use the correct configuration from inside the Jenkins container.

## 7. What It Got Wrong

The initial troubleshooting did not immediately distinguish between the Kubernetes configuration problem and the container/host filesystem boundary.

The solution therefore required inspection and testing of the actual paths inside the Jenkins container.

## 8. What I Changed Before Applying the Output

I verified the paths available inside the Jenkins container.

I then implemented the kubeconfig copy, path replacement, and explicit `KUBECONFIG` setting.

The change was tested through the actual Jenkins deployment process.

---

# AI Governance Entry 3 — Jenkins Production Approval Troubleshooting

## 1. Date

2026-08-18

## 2. Tool Used

ChatGPT and Google Gemini

## 3. Task Description

Troubleshoot the Jenkins production approval stage after the pipeline completed the staging deployment and staging smoke test but did not continue to production.

The pipeline contained a human approval gate before production deployment.

The overall Jenkins pipeline initially had a 15-minute timeout.

## 4. What Was Provided to the AI

The Jenkinsfile, pipeline configuration, and Jenkins runtime behaviour were provided to the AI.

The overall pipeline timeout was configured as:

```groovy
options {
    timeout(time: 15, unit: 'MINUTES')
    buildDiscarder(logRotator(numToKeepStr: '10'))
    disableConcurrentBuilds()
}
```

The pipeline also contained a production approval stage using the Jenkins `input` step.

## 5. What the AI Produced

### ChatGPT

ChatGPT initially suggested increasing the **overall pipeline timeout** from 15 minutes to 30 minutes.

I applied the change, but the pipeline still timed out.

ChatGPT then suggested increasing the overall timeout further to approximately 45 minutes.

I was hesitant to continue increasing the timeout because I did not believe that the pipeline should require such a long period simply to complete a human approval step.

### Google Gemini

I then consulted Google Gemini.

Gemini provided two possible approaches.

**Option 1:** Increase the pipeline timeout further.

**Option 2:** Monitor the Jenkins pipeline while it was running, inspect the console/build output, and select the pending input request when the pipeline reached the approval stage.

The first option was similar to the earlier ChatGPT recommendation.

I chose the second option because I believed that repeatedly increasing the timeout was not addressing the underlying issue.

## 6. What It Got Right

ChatGPT correctly recognized that the pipeline was waiting around the production approval point rather than necessarily failing during the deployment itself.

Gemini's second option correctly directed attention toward the running Jenkins pipeline and the pending human input request.

This led to the correct resolution.

The production approval was not supposed to happen automatically. A human needed to interact with the Jenkins approval request.

## 7. What It Got Wrong

ChatGPT's initial recommendation to increase the overall pipeline timeout from 15 to 30 minutes, and then further toward 45 minutes, did not resolve the underlying problem.

Increasing the timeout only allowed Jenkins to wait longer.

The actual issue was that the pipeline had reached its intentional human approval gate and was waiting for human input.

The AI guidance also did not initially make it clear to me where the Jenkins approval interaction would appear. I initially expected a separate approval UI or pop-up to appear automatically when the pipeline reached the approval stage.

Gemini's first option of increasing the timeout also did not address the underlying problem, so I did not use that option.

## 8. What I Changed Before Applying the Output

I first tested the ChatGPT recommendation by increasing the overall pipeline timeout from 15 to 30 minutes.

When the pipeline still timed out, I did not continue increasing the timeout to 45 minutes because I suspected that the timeout was not the actual problem.

I then followed Gemini's second troubleshooting approach.

While the Jenkins pipeline was running, I inspected the Jenkins console/build interface and found the pending input/approval request.

I selected the request, which opened the approval interface.

I manually entered the required approval reason and submitted the approval.

The pipeline then continued to the subsequent production deployment stages.

This confirmed that the problem was not solved by simply increasing the timeout. The required action was to locate and respond to the pending human approval request.

---

# Human Oversight

AI assistance was used as a development and troubleshooting aid rather than as an authority.

AI-generated recommendations were tested against the actual KijaniKiosk environment before being accepted.

The developer remained responsible for:

* validating AI-generated configuration
* checking security implications
* verifying Kubernetes behaviour
* checking Jenkins behaviour
* confirming staging deployment
* reviewing production readiness
* approving production deployment.

The production deployment was not controlled autonomously by AI.

A human approval gate was implemented in Jenkins and required an authorised user to provide an approval reason before production deployment could continue.

---

# Secrets Policy

No credentials, access keys, passwords, private keys, API tokens, Docker passwords, or Nexus passwords should be committed to the repository.

The Jenkins pipeline uses Jenkins credential references rather than storing credentials directly in the Jenkinsfile.

For example:

```text
nexus-credentials
dockerhub-credentials
```

are referenced by the pipeline while the actual credential values remain in Jenkins.

Temporary authentication files created during the package publishing process are removed after use.

---

# Review Status

The AI governance review has been applied to the AI-assisted development and troubleshooting activities performed during the KijaniKiosk DevOps workflow.

The review covered:

* Jenkins Docker agent configuration;
* Docker socket permissions;
* Kubernetes and Minikube path resolution;
* Jenkins production approval troubleshooting;
* secure credential handling; and
* human approval of production deployment.

AI recommendations were not automatically accepted. They were tested against the actual project environment and changed or rejected where they did not solve the observed problem.

---

# Governance Conclusion

The KijaniKiosk project demonstrates that AI can be useful for DevOps development and troubleshooting while still requiring human oversight.

AI assistance helped identify possible solutions for infrastructure, Jenkins, Kubernetes, and deployment problems. However, several recommendations required testing and human judgment before they were suitable for the actual project.

The Jenkins approval incident provides a clear example:

* ChatGPT suggested increasing the overall timeout.
* The timeout was increased from 15 to 30 minutes, but the problem remained.
* ChatGPT suggested increasing it further.
* Gemini provided two options: increase the timeout or inspect the running Jenkins pipeline for the pending input request.
* The timeout approach was rejected because it did not address the suspected underlying issue.
* The running Jenkins pipeline was inspected.
* The pending approval request was located and selected.
* The required approval reason was entered manually.
* The pipeline then continued.

This demonstrates the principle that **AI recommendations are advisory, not authoritative**.

The final decision remained with the human developer, and production deployment required explicit human approval.
