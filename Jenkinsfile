pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'your-dockerhub-username/clouddeploy-app'
        DOCKER_TAG = "${env.BUILD_NUMBER}"
        GCP_PROJECT_ID = 'your-gcp-project-id'
        GKE_CLUSTER_NAME = 'clouddeploy-cluster'
        GKE_REGION = 'us-central1'
    }

    tools {
        maven 'Maven 3'
        jdk 'JDK 17'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Test') {
            steps {
                dir('app') {
                    sh './mvnw clean package'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('app') {
                    script {
                        dockerImage = docker.build("${DOCKER_IMAGE}:${DOCKER_TAG}")
                    }
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials-id') {
                        dockerImage.push()
                        dockerImage.push('latest')
                    }
                }
            }
        }

        stage('Deploy to GKE') {
            steps {
                withCredentials([file(credentialsId: 'gcp-service-account-key', variable: 'GCP_CREDENTIALS')]) {
                    sh '''
                    # Authenticate with GCP
                    gcloud auth activate-service-account --key-file=${GCP_CREDENTIALS}
                    gcloud config set project ${GCP_PROJECT_ID}
                    gcloud container clusters get-credentials ${GKE_CLUSTER_NAME} --region ${GKE_REGION}

                    # Update Kubernetes Deployment with new image tag
                    sed -i "s|image: .*|image: ${DOCKER_IMAGE}:${DOCKER_TAG}|g" kubernetes/deployment.yaml
                    
                    # Apply Kubernetes manifests
                    kubectl apply -f kubernetes/deployment.yaml
                    kubectl apply -f kubernetes/service.yaml
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline finished."
        }
        success {
            echo "Deployment Successful!"
        }
        failure {
            echo "Deployment Failed."
        }
    }
}
