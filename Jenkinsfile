pipeline {

    agent {
        docker {
            image 'node:18.20.8-bookworm'
            args '-v /tmp:/tmp'
        }
    }

    environment {
    NODE_ENV  = 'test'
    BUILD_DIR = 'dist'
    APP_NAME  = 'kijanikiosk-payments'

    PKG_VERSION      = ''
    GIT_SHORT        = ''
    ARTIFACT_VERSION = ''

    NEXUS_URL       = 'http://192.168.100.33:8081/repository/npm-kijanikiosk/'
    NEXUS_AUTH_PATH = '192.168.100.33:8081/repository/npm-kijanikiosk'    }

    options {
        timeout(time: 10, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
        disableConcurrentBuilds()
    }

    stages {

        stage('Lint') {
            steps {
                echo "Running lint checks for ${APP_NAME}..."
                sh 'npm run lint'
            }
        }

        stage('Build') {
            steps {
                echo "Installing dependencies for ${APP_NAME}..."
                sh 'npm ci'

                echo "Building application..."
                sh 'npm run build'

                echo "Verifying build output..."

                sh '''
                    set -e
                    test -d "${BUILD_DIR}" || {
                        echo "ERROR: build directory not found"
                        exit 1
                    }

                    echo "Build output: $(ls ${BUILD_DIR} | wc -l) files in ${BUILD_DIR}/"
                '''
            }
        }

        stage('Verify') {
            parallel {

                stage('Test') {
                    steps {
                        echo "Running tests for ${APP_NAME}..."

                        sh '''
                            set -e
                            npm test
                        '''
                    }

                    post {
                        always {
                            junit allowEmptyResults: true,
                                  testResults: 'test-results/*.xml'
                        }
                    }
                }

                stage('Security Audit') {
                    steps {
                        echo "Running security audit..."

                        sh '''
                            set -e
                            npm audit --audit-level=high
                        '''
                    }
                }
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts artifacts: "${BUILD_DIR}/**",
                                 fingerprint: true,
                                 onlyIfSuccessful: true
            }
        }

     stage('Publish') {
    steps {
        script {

            def pkgVersion = sh(
                script: "node -p \"require('./package.json').version\"",
                returnStdout: true
            ).trim()

            def gitShort = sh(
                script: "git rev-parse --short HEAD",
                returnStdout: true
            ).trim()

            def artifactVersion = "${pkgVersion}-${gitShort}"

            echo "Publishing version: ${artifactVersion}"

            withCredentials([usernamePassword(
                credentialsId: 'nexus-credentials',
                usernameVariable: 'NEXUS_USER',
                passwordVariable: 'NEXUS_PASS'
            )]) {

                sh """
                    set -e

                    trap 'rm -f .npmrc' EXIT

                    NEXUS_TOKEN=\$(echo -n "\${NEXUS_USER}:\${NEXUS_PASS}" | base64 | tr -d '\\n')

                    cat > .npmrc <<EOF
registry=${NEXUS_URL}
//${NEXUS_AUTH_PATH}/:_auth=\${NEXUS_TOKEN}
always-auth=true
EOF

                    echo "Publishing ${APP_NAME}:${artifactVersion}"

                    npm version ${artifactVersion} --no-git-tag-version

                    echo "Package version after update:"
                    grep version package.json

                    npm publish --registry=${NEXUS_URL}
                """
            }
        }
    }
}
    post {

        always {
            junit allowEmptyResults: true,
                  testResults: 'test-results/*.xml'

            cleanWs()
        }

        success {
            echo "Pipeline succeeded: ${env.APP_NAME} version ${env.ARTIFACT_VERSION}"
            echo "Artifact URL: ${env.NEXUS_URL}"
        }

        failure {
            echo "Pipeline FAILED: ${APP_NAME} build ${BUILD_NUMBER}"
            echo "Check logs: ${BUILD_URL}"
        }

        changed {
            echo "Build status changed to ${currentBuild.currentResult}"
        }
    }
}