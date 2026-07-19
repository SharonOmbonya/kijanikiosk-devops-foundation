pipeline {
    agent {
        docker {
            image 'node:18.20.8-alpine'
            // Host network mode isolates container traffic and bridges host connectivity natively
            args '-v /tmp:/tmp --network=host'
        }
    }

    environment {
        NODE_ENV      = 'test'
        BUILD_DIR     = 'dist'
        APP_NAME      = 'kijanikiosk-payments'
        
        // Single Source of Truth for Network Registries
        NEXUS_URL     = 'http://192.168.0.16:8081/repository/npm-kijanikiosk/'

        // Initialized pipeline context tracking variables to prevent pollution
        PKG_VERSION            = ''
        GIT_SHORT              = ''
        ARTIFACT_VERSION       = ''
        NEXUS_CLEAN_AUTH_PATH  = ''
    }

    options {
        timeout(time: 15, unit: 'MINUTES')
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

                echo "Verifying build output existence..."
                sh '''
                    set -e
                    test -d "${BUILD_DIR}" || {
                        echo "ERROR: Build directory '${BUILD_DIR}' not found."
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
                }
                stage('Security Audit') {
                    steps {
                        echo "Running security vulnerability audit..."
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
                    // 1. Dynamic version extraction from package.json
                    env.PKG_VERSION = sh(
                        script: "node -p \"require('./package.json').version\"",
                        returnStdout: true
                    ).trim()

                    env.GIT_SHORT = "${env.GIT_COMMIT}".take(7)
                    env.ARTIFACT_VERSION = "${env.PKG_VERSION}-${env.GIT_SHORT}"

                    // 2. DYNAMIC PROTOCOL SANITIZATION (Zero Hardcoding)
                    // Automatically turns 'http://192.168.0.16...' into '192.168.0.16...'
                    env.NEXUS_CLEAN_AUTH_PATH = env.NEXUS_URL.replace("http://", "").replace("https://", "")
                }

                withCredentials([usernamePassword(
                    credentialsId: 'nexus-credentials',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    // Shielded within pure single quotes to avoid Jenkins escaping confusion
                    sh '''
                        set -e

                        rm -f .npmrc
                        trap "rm -f .npmrc" EXIT

                        # Generate base64 auth token inside the execution shell context safely
                        NEXUS_TOKEN=$(echo -n "${NEXUS_USER}:${NEXUS_PASS}" | base64 | tr -d '\\n')

                        # Write configuration variables cleanly passed from pipeline env map
                        echo "registry=${NEXUS_URL}" > .npmrc
                        echo "//${NEXUS_CLEAN_AUTH_PATH}:_auth=${NEXUS_TOKEN}" >> .npmrc
                        echo "always-auth=true" >> .npmrc

                        echo "Publishing ${APP_NAME}:${ARTIFACT_VERSION} to Nexus Registry"

                        # Mutate version in package.json dynamically before distribution
                        npm version ${ARTIFACT_VERSION} --no-git-tag-version

                        # Publish picks up structural repository values directly from temporary local config context
                        npm publish
                    '''
                }
            }
        }
    }

    post {
        always {
            junit allowEmptyResults: true, testResults: 'test-results/*.xml'
            cleanWs()
        }
        success {
            echo "Pipeline succeeded: ${APP_NAME} version ${env.ARTIFACT_VERSION} is delivered."
            echo "Artifact URL: ${NEXUS_URL}"
        }
        failure {
            echo "Pipeline FAILED: ${APP_NAME} build #${BUILD_NUMBER}"
            echo "Check logs here: ${BUILD_URL}"
        }
        changed {
            echo "Build status transitioned to: ${currentBuild.currentResult}"
        }
    }
}