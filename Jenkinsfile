pipeline {
    agent {
        docker { 
            image 'node:18.20.8-alpine' // pinned, not latest
            reuseNode true
        }
    }
    environment {
        // 1. All values come from Jenkins "Environment Variables" or Credentials
        NEXUS_URL = "${env.NEXUS_URL}" // Set this in Jenkins Job Config > Environment Variables
        NEXUS_REPO = "${env.NEXUS_REPO}" // e.g. npm-kijanikiosk
        PACKAGE_NAME = "${env.PACKAGE_NAME}" // e.g. kijanikiosk-payments
    }
    options {
        timeout(time: 10, unit: 'MINUTES')
        disableConcurrentBuilds()
    }
    stages {
        stage('Lint') {
            steps {
                sh 'npm run lint'
            }
        }
        stage('Build') {
            steps {
                sh 'npm ci'
                sh 'npm run build'
            }
        }
        stage('Verify') {
            parallel {
                stage('Test') {
                    steps { sh 'npm test' }
                }
                stage('Security Audit') {
                    steps { sh 'npm audit --audit-level=high' }
                }
            }
        }
        stage('Archive') {
            steps {
                archiveArtifacts artifacts: 'dist/**', fingerprint: true
            }
        }
        stage('Publish') {
            steps {
                script {
                    def version = sh(script: "node -p \"require('./package.json').version\"", returnStdout: true).trim()
                    def gitSha = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    env.ARTIFACT_VERSION = "${version}-${gitSha}" // Requirement 2: semver-gitsha
                }
                // 2. Username + Password come from Jenkins Credentials ONLY
                withCredentials([usernamePassword(credentialsId: "${env.NEXUS_CREDENTIAL_ID}", usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh '''
                        # Create .npmrc and delete in same shell. No hardcoded URL
                        echo "//${NEXUS_URL#http://}/:_auth=$(echo -n $NEXUS_USER:$NEXUS_PASS | base64)" > .npmrc
                        echo "registry=http://${NEXUS_URL}" >> .npmrc
                        echo "always-auth=true" >> .npmrc
                        
                        npm version $ARTIFACT_VERSION --no-git-tag-version
                        npm publish
                        
                        rm -f .npmrc
                    '''
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
        success {
            echo "Artifact published: http://${NEXUS_URL}${PACKAGE_NAME}/-/${PACKAGE_NAME}-${ARTIFACT_VERSION}.tgz"
        }
        failure {
            echo "Pipeline FAILED: ${PACKAGE_NAME} build ${BUILD_NUMBER}"
        }
        changed {
            echo "Build status changed. Previous: ${currentBuild.previousBuild?.result}, Current: ${currentBuild.result}"
        }
    }
}