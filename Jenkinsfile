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
    ARTIFACT_VERSION = '1.0.${BUILD_NUMBER}'

    NEXUS_URL        = 'http://192.168.0.16:8081/repository/npm-kijanikiosk/'
    NEXUS_AUTH_PATH  = '192.168.0.16:8081/repository/npm-kijanikiosk'  
    }

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

                    test "$(find "${BUILD_DIR}" -type f | wc -l)" -gt 0 || {
                        echo "ERROR: Build directory is empty."
                        exit 1

                    }
                                
                    echo "Build output: $(find "${BUILD_DIR}" -type f | wc -l) files in ${BUILD_DIR}/"
                    echo "Build output verified."
                '''

                stash name: 'build-output',
                      includes: "${BUILD_DIR}/**,package.json"

                
            }
        }

        stage('Verify') {
            parallel {

                stage('Test') {
                    steps {
                        unstash 'build-output'

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
        withCredentials([usernamePassword(
            credentialsId: 'nexus-credentials',
            usernameVariable: 'NEXUS_USER',
            passwordVariable: 'NEXUS_PASS'
        )]) {
            sh '''
                set -e

                # Generate base64 token from NEXUS_USER:NEXUS_PASS
                NEXUS_AUTH=$(printf "%s:%s" "$NEXUS_USER" "$NEXUS_PASS" | base64 | tr -d '\\n')

                # Remove .npmrc after publish (success or failure)
                trap "rm -f .npmrc" EXIT

                # Configure npm registry authentication
                cat > .npmrc <<EOF
registry=http://192.168.0.16:8081/repository/npm-kijanikiosk/
//192.168.0.16:8081/repository/npm-kijanikiosk/:_auth=$NEXUS_AUTH
//192.168.0.16:8081/repository/npm-kijanikiosk/:always-auth=true
EOF

                # Update package version
                npm version "$ARTIFACT_VERSION" --no-git-tag-version

                # Publish package to Nexus
                npm publish --registry=http://192.168.0.16:8081/repository/npm-kijanikiosk/
            '''
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
            echo "Pipeline FAILED: ${env.APP_NAME} build ${BUILD_NUMBER}"
            echo "Check logs: ${BUILD_URL}"
        }

        changed {
            echo "Build status changed to ${currentBuild.currentResult}"
        }
    }
}