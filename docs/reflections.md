# KijaniKiosk Capstone Reflection

## 1. What did you get wrong?

One technical decision I got wrong was using the existing `node:18.20.8-bookworm` image for the Jenkins agent. The image did not have the environment required for the Minikube/Kubernetes workflow, which caused problems with access to the Minikube path and Kubernetes tooling. I corrected this by using the project-specific `kijanikiosk-jenkins-agent:node18-kubectl` image and the required Jenkins agent configuration, including the Minikube and kubeconfig mounts.

I also initially started the Jenkins pipeline before confirming that the required ngrok URL was running and connected correctly. This caused the pipeline workflow to fail because the expected endpoint was not available. I corrected the issue and learned that external dependencies such as the ngrok tunnel must be verified before starting an automated pipeline run.

These mistakes showed me that a pipeline can be correctly configured but still fail because its execution environment or external dependencies have not been prepared correctly.

## 2. What was the most important thing you learned?

The most important thing I learned was that DevOps automation depends on the environment around the pipeline, not only on the pipeline configuration itself. This became particularly clear during the Jenkins and Kubernetes work in Weeks 9 and 10.

I learned that the Jenkins agent image must contain the tools and configuration required by the deployment environment. I also learned the importance of validating dependencies before triggering automation. My understanding changed from thinking mainly about whether the pipeline stages were correctly written to also considering whether the agent, Kubernetes environment, credentials, paths, networking, and external services were ready for the pipeline to run successfully.

The Prometheus work also reinforced the importance of verification. Having a Prometheus alert rule present and healthy is different from proving that an alert has actually fired, so monitoring evidence must be interpreted rather than simply collected.

## 3. If you had a second pass, what would you change?

With a second pass, I would improve the workflow preparation and verification before running the pipeline. Specifically, I would:

- Verify the Jenkins agent image and all required Kubernetes/Minikube paths before running the pipeline.
- Confirm that the ngrok URL is active and connected before triggering an automated pipeline run.
- Add clearer pre-flight checks for external dependencies so that failures are detected before the main pipeline execution.
- Expand the monitoring tests so that the Prometheus alert can be deliberately triggered and its firing state captured as evidence.
- Improve the documentation of the Jenkins agent requirements so that another engineer can reproduce the environment without having to troubleshoot the same issues.

These changes would make the project more reproducible and reduce avoidable failures during deployment and verification.
