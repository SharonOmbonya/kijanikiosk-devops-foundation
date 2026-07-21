# Reflection

## 1. At what point this week did you discover that two requirements were in tension with each other? Describe the tension and what you chose to prioritise.

One challenge I discovered was the balance between using a lightweight Docker image and having a reliable pipeline environment. Initially, I used a Node Alpine image because it was smaller and faster to download. However, I experienced issues because some required tools, such as Git, were not available in the image by default. This affected parts of the pipeline that depended on repository information and version generation.

The requirement was to use an isolated and efficient environment, but the pipeline also needed to reliably create traceable artifacts. I chose to prioritise pipeline reliability and consistency by moving to a Node Bookworm image. Although it was a larger image, it provided a more complete environment and reduced failures caused by missing dependencies.

Another challenge was artifact versioning. Initially, the generated versions did not always follow the required semver-git SHA format. I had to review how the version value was created and adjust the approach so that each artifact could be traced back to the exact source change. This reinforced the importance of producing reproducible artifacts rather than only creating successful builds.

## 2. The board document is written for Nia. Rewrite one sentence from that document in the technical language you would use in the Jenkinsfile comment or in a conversation with Osei. What information is the same in both versions and what is different?

Board document version:

"Every time a developer makes a change and pushes new code to the shared repository, an automated delivery process begins to ensure that only code meeting the required quality checks can become an approved version."

Technical version:

"The Jenkins pipeline is triggered from source control changes and executes sequential stages for linting, building, verification, artifact archiving, and publishing. Failed stages stop downstream execution to prevent invalid artifacts from being released."

The information is the same because both explain that code changes trigger automated checks before an approved version is created. The difference is the audience and level of detail. The board version focuses on the business outcome: protecting quality and preventing unreliable software from being released. The technical version focuses on implementation details such as pipeline stages, execution flow, and failure handling.

## 3. Looking at the complete pipeline as a system: if KijaniKiosk grows from four developers to forty, which single part of this week's pipeline would break first? What would need to change and why?

The artifact versioning and publishing process would likely become the first area requiring improvement as the number of developers increases. With more developers creating changes, the number of builds and published artifacts will increase significantly. Without stronger version management and artifact retention policies, it could become difficult to track which version belongs to which change.

The pipeline would need improved artifact management, stronger naming conventions, and possibly additional controls around release approval. The current pipeline provides a strong foundation by including Git SHA information in versions and storing artifacts in Nexus, but a larger development team would require more automation around ownership, cleanup policies, and release tracking.

The experience building this pipeline showed that reliability depends on more than making each stage run successfully. The pipeline must also create consistent, traceable results that can be understood and maintained as the project grows.
