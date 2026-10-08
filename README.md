# CloudDeploy CI/CD Deployment Platform

This repository contains the infrastructure and source code for the CloudDeploy project—a containerized Spring Boot application with a fully automated CI/CD pipeline and Cloud (GCP) infrastructure.

## Project Structure

* **`app/`**: Contains the Spring Boot Java application and a multi-stage `Dockerfile` to containerize it.
* **`terraform/`**: Contains HashiCorp Terraform scripts to automatically provision a Google Kubernetes Engine (GKE) cluster, networking, and node pools on Google Cloud Platform (GCP).
* **`kubernetes/`**: Contains Kubernetes manifests (`deployment.yaml`, `service.yaml`) used to deploy and expose the application securely.
* **`Jenkinsfile`**: Contains the declarative CI/CD pipeline definition for building, testing, containerizing, and deploying the application using Jenkins.

## Prerequisites

* **GCP Account**: With a valid project and billing enabled.
* **Docker Hub**: Account to push/pull Docker images.
* **Jenkins**: Installed and configured with Docker, Maven, JDK 17, and GCP credentials.
* **Terraform**: CLI installed locally.

## Setup Instructions

1. **Infrastructure Provisioning (Terraform)**
   ```bash
   cd terraform
   terraform init
   terraform plan -var="project_id=YOUR_GCP_PROJECT_ID"
   terraform apply -var="project_id=YOUR_GCP_PROJECT_ID"
   ```

2. **CI/CD Configuration**
   * Link your Jenkins instance to this repository.
   * Add the following credentials to Jenkins:
     * `dockerhub-credentials-id` (Username with password)
     * `gcp-service-account-key` (Secret file containing your GCP JSON key)
   * Update the environment variables at the top of the `Jenkinsfile` with your details.

3. **Application Deployment**
   * Once triggered, Jenkins will automatically checkout the code, build the Maven project, create a Docker image, push it to Docker Hub, and apply the Kubernetes manifests to your GKE cluster.
   * Access the application by finding the external IP of the LoadBalancer:
     ```bash
     kubectl get services clouddeploy-app-service
     ```
