pipeline {
    agent any

    parameters {
        booleanParam(name: 'FAIL_ON_SECRETS', defaultValue: true, description: 'Fail build if Gitleaks detects hardcoded secrets')
        booleanParam(name: 'FAIL_ON_SEMGREP', defaultValue: true, description: 'Fail build if Semgrep detects high-severity SAST flaws')
        booleanParam(name: 'FAIL_ON_SONAR_GATE', defaultValue: true, description: 'Fail build if SonarQube Quality Gate fails')
        string(name: 'TRIVY_SEVERITY_THRESHOLD', defaultValue: 'HIGH,CRITICAL', description: 'Comma-separated severity threshold for Trivy security gate')
        booleanParam(name: 'FAIL_ON_ZAP_HIGH', defaultValue: true, description: 'Fail build if OWASP ZAP identifies high-risk vulnerabilities on staging')
    }

    environment {
        DOCKER_IMAGE = 'your-dockerhub-username/clouddeploy-app'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        GCP_PROJECT_ID = 'your-gcp-project-id'
        GKE_CLUSTER_NAME = 'clouddeploy-cluster'
        GKE_REGION = 'us-central1'
        SONAR_SCANNER_HOME = tool 'SonarQubeScanner'
    }

    tools {
        maven 'Maven 3'
        jdk 'JDK 17'
    }

    options {
        timeout(time: 1, unit: 'HOURS')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '15'))
    }

    stages {
        stage('Checkout') {
            steps {
                echo '=== Stage 1: Checkout Source Code ==='
                checkout scm
                sh 'mkdir -p reports/security'
            }
        }

        stage('Secret Detection (Gitleaks)') {
            steps {
                echo '=== Stage 2: Secret Scanning via Gitleaks ==='
                sh """
                EXIT_ON_LEAK=${params.FAIL_ON_SECRETS} ./security/scripts/gitleaks-scan.sh || {
                    if [ "${params.FAIL_ON_SECRETS}" = "true" ]; then
                        echo "Security Gate Violation: Hardcoded secrets detected!"
                        exit 1
                    fi
                }
                """
            }
        }

        stage('SAST Analysis (Semgrep)') {
            steps {
                echo '=== Stage 3: Static Application Security Testing via Semgrep ==='
                sh """
                ./security/scripts/semgrep-scan.sh || {
                    if [ "${params.FAIL_ON_SEMGREP}" = "true" ]; then
                        echo "Security Gate Violation: Semgrep found security flaws!"
                        exit 1
                    fi
                }
                """
            }
        }

        stage('Build & Unit Tests') {
            steps {
                echo '=== Stage 4: Maven Compilation, Testing & JaCoCo Coverage ==='
                dir('app') {
                    sh 'mvn clean test jacoco:report'
                }
            }
        }

        stage('SonarQube Code Quality & Gate') {
            steps {
                echo '=== Stage 5: SonarQube Analysis & Quality Gate Enforcement ==='
                withSonarQubeEnv('SonarQubeServer') {
                    dir('app') {
                        sh '''
                        mvn sonar:sonar \
                            -Dsonar.projectKey=clouddeploy-app \
                            -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                        '''
                    }
                }
                timeout(time: 5, unit: 'MINUTES') {
                    script {
                        def qg = waitForQualityGate()
                        if (qg.status != 'OK') {
                            if (params.FAIL_ON_SONAR_GATE) {
                                error "Security Gate Violation: SonarQube Quality Gate failure (${qg.status})!"
                            } else {
                                echo "WARNING: SonarQube quality gate failed with ${qg.status}, but failure is suppressed."
                            }
                        }
                    }
                }
            }
        }

        stage('Dependency Vulnerability Scan (Trivy SCA)') {
            steps {
                echo '=== Stage 6: Trivy Dependency & Filesystem Scan ==='
                sh """
                SEVERITY_LEVELS="${params.TRIVY_SEVERITY_THRESHOLD}" ./security/scripts/trivy-scan.sh fs app
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '=== Stage 7: Build Container Image ==='
                dir('app') {
                    script {
                        dockerImage = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                    }
                }
            }
        }

        stage('Container Image Security Scan (Trivy)') {
            steps {
                echo '=== Stage 8: Trivy Container Image Vulnerability Scan ==='
                sh """
                SEVERITY_LEVELS="${params.TRIVY_SEVERITY_THRESHOLD}" ./security/scripts/trivy-scan.sh image "${DOCKER_IMAGE}:${DOCKER_TAG}"
                """
            }
        }

        stage('Push Docker Image') {
            steps {
                echo '=== Stage 9: Push Scanned Image to Docker Hub ==='
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials-id') {
                        dockerImage.push()
                        dockerImage.push('latest')
                    }
                }
            }
        }

        stage('Deploy to Staging (GKE)') {
            steps {
                echo '=== Stage 10: Deploy Application to Staging Environment ==='
                withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GCP_CREDENTIALS')]) {
                    sh '''
                    gcloud auth activate-service-account --key-file=${GCP_CREDENTIALS}
                    gcloud config set project ${GCP_PROJECT_ID}
                    gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --region ${GKE_REGION}

                    kubectl create namespace staging --dry-run=client -o yaml | kubectl apply -f -

                    sed -i "s|image: .*|image: ${DOCKER_IMAGE}:${DOCKER_TAG}|g" kubernetes/staging-deployment.yaml
                    kubectl apply -f kubernetes/staging-deployment.yaml
                    kubectl apply -f kubernetes/staging-service.yaml

                    # Wait for rollout
                    kubectl rollout status deployment/clouddeploy-app-staging -n staging --timeout=120s
                    '''
                }
            }
        }

        stage('DAST Dynamic Security Scan (OWASP ZAP)') {
            steps {
                echo '=== Stage 11: OWASP ZAP DAST against Staging Endpoint ==='
                script {
                    withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GCP_CREDENTIALS')]) {
                        sh '''
                        # Retrieve staging external IP
                        STAGING_IP=$(kubectl get svc clouddeploy-app-staging-service -n staging -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
                        if [ -z "$STAGING_IP" ]; then
                            STAGING_IP="http://localhost:8080"
                        else
                            STAGING_IP="http://${STAGING_IP}"
                        fi

                        FAIL_ON_HIGH=${params.FAIL_ON_ZAP_HIGH} ./security/scripts/owasp-zap-scan.sh "${STAGING_IP}"
                        '''
                    }
                }
            }
        }

        stage('Promote to Production (GKE)') {
            steps {
                echo '=== Stage 12: Zero-Downtime Rolling Update to Production ==='
                withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GCP_CREDENTIALS')]) {
                    sh '''
                    kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -

                    sed -i "s|image: .*|image: ${DOCKER_IMAGE}:${DOCKER_TAG}|g" kubernetes/deployment.yaml
                    kubectl apply -f kubernetes/deployment.yaml
                    kubectl apply -f kubernetes/service.yaml

                    # Verify rolling update status
                    kubectl rollout status deployment/clouddeploy-app-deployment -n production --timeout=180s
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "Archiving security scan reports and test results..."
            junit allowEmptyResults: true, testResults: 'app/target/surefire-reports/*.xml'
            archiveArtifacts allowEmptyArchive: true, artifacts: 'reports/security/**'
            cleanWs deleteDirs: true, notFailBuild: true
        }
        success {
            echo "=========================================================="
            echo " DevSecOps Pipeline Finished Successfully!"
            echo " All Security Gates (Gitleaks, Semgrep, SonarQube, Trivy, ZAP) Passed."
            echo " Production Deployment Live on Google Kubernetes Engine."
            echo "=========================================================="
        }
        failure {
            echo "=========================================================="
            echo " ALERT: DevSecOps Pipeline Failed!"
            echo " Check security gate reports in reports/security/ for violations."
            echo "=========================================================="
        }
    }
}
