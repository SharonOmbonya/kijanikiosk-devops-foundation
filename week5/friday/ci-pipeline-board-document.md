# KijaniKiosk CI Pipeline: Board Overview

## How Code Becomes a Trusted Version

When a developer makes a change and pushes new code to the shared repository, an automated delivery process begins. The purpose of this process is to ensure that only code that meets the required quality checks can become an approved version that is stored for future use.

The process starts by connecting the source code repository to the delivery pipeline. When new changes are detected, the pipeline retrieves the latest version of the application and runs a controlled set of checks inside an isolated environment. This environment uses a fixed Docker image so that the same tools and operating conditions are used every time the pipeline runs. This reduces differences between developer machines and the delivery system.

The pipeline first performs a Lint check. This reviews the code structure and identifies formatting or quality issues before further work is performed. Running this check early follows a fail-fast approach: problems are discovered as soon as possible, reducing wasted processing time.

If the code passes the initial quality check, the pipeline moves to the Build stage. Dependencies are installed and the application is prepared for packaging. The pipeline verifies that the required scripts and directories exist before continuing. A successful build confirms that the application can be assembled correctly.

After building, the pipeline performs verification checks in parallel. The Test process confirms that the application behaves as expected by running automated tests. At the same time, the Security Audit branch performs additional checks to identify potential security concerns. Running these checks together improves speed while maintaining confidence in the quality of the application.

Once verification is complete, the pipeline archives the build output. The archived artifact receives fingerprinting information, allowing the team to track exactly which source change produced a specific version. This traceability is important because it allows the organisation to identify, review, and reproduce approved application versions.

The final stage publishes the approved artifact to the internal registry. Before publishing, the pipeline securely retrieves the required access information through managed credentials. Sensitive information is not stored inside the code. The published version follows a unique version format containing the application version and source change reference, ensuring that each approved release can be identified.

| Pipeline Stage | What It Confirms                                                    |
| -------------- | ------------------------------------------------------------------- |
| Lint           | The code meets required quality standards before further processing |
| Build          | The application can be prepared successfully                        |
| Verify         | Automated tests and security checks pass                            |
| Archive        | The approved build output is stored and traceable                   |
| Publish        | The verified version is available in the internal registry          |

## What Happens When Something Goes Wrong

The pipeline is designed to prevent incomplete or unverified software from becoming an approved version. If a developer introduces a problem, the pipeline stops at the stage where the issue is detected.

For example, if code quality checks fail, the application will not continue to building or verification. If the build process fails, later activities such as storing or publishing the application are skipped. If testing identifies a problem, the application is prevented from reaching the artifact registry because it has not met the required quality standards.

This behaviour protects the organisation by ensuring that failures are visible immediately and that unreliable versions do not move forward. The team receives a clear failure notification, allowing the issue to be corrected before another attempt is made. This provides a consistent process whether a failure occurs during working hours or outside normal office hours.

## Current Scope and Future Improvements

The current pipeline provides automated validation, controlled artifact creation, and secure publishing of approved application versions. It improves reliability by ensuring that every published version has passed the same checks and can be traced back to its source change.

However, the pipeline does not yet include automatic deployment to production environments, advanced monitoring after release, or automated rollback if a deployed version experiences issues. These capabilities can be added in future improvements as the delivery process expands from continuous integration into full continuous delivery.
