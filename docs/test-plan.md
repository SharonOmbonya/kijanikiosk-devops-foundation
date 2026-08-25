# KijaniKiosk Capstone Test Plan

## Purpose

This test plan defines the checks to be performed during the capstone review to verify that the KijaniKiosk delivery system works as designed.

## 1. Fresh Setup

- Clone the repository from GitHub.
- Follow the README setup instructions.
- Verify that the required infrastructure, Kubernetes environment, and application components can be started.

## 2. Happy Path

- Create or update a feature branch with a change.
- Open a pull request against `main`.
- Review and merge the pull request into `main`.
- Verify that the merge to `main` triggers the Jenkins pipeline automatically.
- Confirm that the application is built and verified.
- Confirm that the application is deployed to the `kijani-staging` namespace.
- Confirm that the staging smoke test passes.
- Verify that the production approval gate appears only after the staging smoke test passes.
- Approve the production deployment.
- Confirm that the application is successfully deployed to the production namespace.

## 3. Failure Path

- Introduce the controlled Kubernetes readiness probe fault.
- Deploy the affected workload.
- Verify that Kubernetes reports the affected workload as not ready.
- Verify that the deployment monitoring workflow detects the failure.
- Observe and document the resulting pipeline or Kubernetes behaviour.

## 4. AI Governance

- Review `docs/ai-governance-log.md`.
- Verify that AI-assisted work is documented using the required governance format.
- Check that the entries identify what AI produced, what was incorrect or required review, and what changes were made by the human reviewer.
- Confirm that the documented governance process reflects actual project work.
