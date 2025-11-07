# Spring Boot CI/CD with Docker, Kubernetes, and Nexus

## Project Overview
This project automates the CI/CD of a Spring Boot application using Docker, Nexus, and Kubernetes.  
The Jenkins pipeline performs the following tasks:

- Build and package the Spring Boot application using Maven
- Deploy the JAR artifact to Nexus
- Build Docker image of the application
- Push Docker image to Docker Hub
- Deploy the application stack (MySQL, Nexus, Spring Boot) in Kubernetes (kubeadm)
- Optional cleanup of Dev/Prod environments

## System Requirements

### Jenkins Server
- Ubuntu 24.04 (4gb RAM + 2CPU + 20gb Storage)
- Docker & Docker Compose installed
- Kubectl installed
- Java 17
- Maven (if building outside Docker)

### Kubernetes Cluster (kubeadm)
- At least 1 control plane node
- At least 1 worker node
- Node ports open for app access (e.g., 30081, 30085)
- Persistent storage available for MySQL & Nexus

### Nexus Repository
- Nexus 3.x running
- Admin credentials (username/password)
- Create repositories:
  - `maven-releases`
  - `maven-snapshots`

### Docker Hub
- Account with username/password for Jenkins push access

---

## Project Structure
├── Dockerfile # Multi-stage Dockerfile for build & runtime
├── settings.xml # Maven settings for Nexus credentials
├── k8s/
│ ├── mysql.yaml # MySQL Deployment + Service
│ ├── nexus.yaml # Nexus Deployment + Service
│ ├── spring-app.yaml # Spring Boot Deployment + Service
├── application.properties # Spring Boot configuration
├── fetch-and-prepare-kubeconfig.sh
└── Jenkinsfile # Declarative pipeline


---

## Jenkins Manual Setup

1. **Install Plugins**
   - Docker Pipeline
   - Kubernetes CLI Plugin
   - Git

2. **Create Jenkins Credentials**
   - Docker Hub credentials (username/password)
     - ID: `dockerhub-credentials-id`
   - Kubernetes Kubeconfig (Secret file)
     - ID: `kubeconfig-credentials-id`
   - Nexus credentials (optional for env variables)
     - ID: `nexus-credentials-id`  

3. **Create Pipeline Job**
   - Pipeline type: Declarative
   - Add parameters:
     - `DOCKER_IMAGE_NAME` (default: `spring_app_sak`)
     - `DOCKER_TAG` (default: `${BUILD_ID}`)
     - `DEPLOY_ENV` (choices: `dev`, `prod`)
     - `CLEANUP` (boolean, default false)
   - Copy the provided Jenkinsfile

4. **Install Required Tools on Jenkins Agent**
   - Docker
   - Kubectl
   - Maven (optional if using Docker build stage)
   - Java 17 runtime

---

## Kubernetes Setup

1. **Copy kubeconfig to Jenkins**
```bash
   ./fetch-and-prepare-kubeconfig.sh
```
