pipeline {

   agent {
        docker {
            image 'kijanikiosk-jenkins-agent:node18-kubectl'
            args '--network minikube -v /tmp:/tmp -v /home/sharon/.kube:/home/node/.kube:ro -v /home/sharon/.minikube:/home/sharon/.minikube:ro'
        }
    }


    environment {
        NODE_ENV  = 'test'
        BUILD_DIR = 'dist'
        APP_NAME  = 'kijanikiosk-payments'

        // Nexus
        NEXUS_URL = 'http://172.17.0.1:8081/repository/npm-kijanikiosk/'
        NEXUS_AUTH_PATH = '172.17.0.1:8081/repository/npm-kijanikiosk'
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
                unstash 'build-output'

                script {
                    env.ARTIFACT_VERSION = sh(
                        script: "node -p \"require('./package.json').version\"",
                        returnStdout: true
                    ).trim() + "-" + sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()

                    echo "ARTIFACT_VERSION=${env.ARTIFACT_VERSION}"
                }

                withCredentials([usernamePassword(
                    credentialsId: 'nexus-credentials',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {

                    sh '''
                        set -e

                        trap "rm -f .npmrc" EXIT

                        NEXUS_TOKEN=$(echo -n "${NEXUS_USER}:${NEXUS_PASS}" | base64 | tr -d '\\n')

                        cat > .npmrc <<EOF2
registry=${NEXUS_URL}
//${NEXUS_AUTH_PATH}/:_auth=${NEXUS_TOKEN}
always-auth=true
EOF2

                        echo "Publishing ${APP_NAME}:${ARTIFACT_VERSION}"

                        npm version ${ARTIFACT_VERSION} --no-git-tag-version

                        npm publish --registry=${NEXUS_URL}
                    '''
                }
            }
        }

        /*
         * TRACK A
         * Deploy automatically to the isolated staging namespace.
         */
        stage('Deploy to Staging') {
            steps {
                echo "Deploying ${APP_NAME} to kijani-staging..."

                sh '''
                    set -e

                    sed \
                      -e "s|image: .*kk-payments:.*|image: kijanikiosk/kk-payments:${BUILD_NUMBER}|" \
                      k8s/kk-payments-deployment.yaml \
                      > /tmp/kk-payments-staging.yaml

                    kubectl apply -f /tmp/kk-payments-staging.yaml

                    kubectl rollout status deployment/kk-payments \
                      -n kijani-staging \
                      --timeout=120s
                '''
            }
        }

        /*
         * Track A requires the production approval gate
         * ONLY after the staging smoke test passes.
         */
        stage('Smoke Test Staging') {
            steps {
                echo "Running staging smoke test..."

                sh '''
                    set -e

                    kubectl get deployment kk-payments -n kijani-staging

                    kubectl get pods \
                      -n kijani-staging \
                      -l app=kk-payments

                    kubectl rollout status deployment/kk-payments \
                      -n kijani-staging \
                      --timeout=120s

                    echo "Staging smoke test passed."
                '''
            }
        }

        stage('Approve Production Deployment') {
            steps {
                script {
                    def approval = input(
                        message: "Staging smoke test passed. Deploy kk-payments:${BUILD_NUMBER} to production?",
                        ok: 'Deploy',
                        submitter: 'tendo,nia,osei',
                        submitterParameter: 'APPROVED_BY',
                        parameters: [
                            text(
                                name: 'APPROVAL_REASON',
                                description: 'Reason for approval (required for audit trail)'
                            )
                        ]
                    )

                    echo "Production deployment approved."
                    echo "Approval details: ${approval}"
                }
            }
        }

        stage('Deploy to Production') {
            steps {
                echo "Deploying ${APP_NAME} to production..."

                sh '''
                    set -e

                    sed \
                      -e "s/namespace: kijani-staging/namespace: default/" \
                      -e "s|image: .*kk-payments:.*|image: kijanikiosk/kk-payments:${BUILD_NUMBER}|" \
                      k8s/kk-payments-deployment.yaml \
                      > /tmp/kk-payments-production.yaml

                    kubectl apply -f /tmp/kk-payments-production.yaml

                    kubectl rollout status deployment/kk-payments \
                      -n default \
                      --timeout=120s
                '''
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
