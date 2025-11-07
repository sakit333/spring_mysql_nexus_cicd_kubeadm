/*
################################################################################
#  Jenkins Declarative Pipeline
#  Designed and Developed by: sak_shetty
#  Description:
#    CI/CD Pipeline for Spring Boot Application with Docker and Kubernetes
#    Features:
#      - Build Docker image and tag with BUILD_ID and latest
#      - Push to Docker Hub
#      - Deploy Dev environment with Docker Compose
#      - Deploy Prod environment on kubeadm cluster (MySQL, Nexus, Spring Boot)
#      - Cleanup steps for Dev and Prod
################################################################################
*/

pipeline {
    agent any
    parameters {
        string(name: 'DOCKER_IMAGE_NAME', defaultValue: 'spring_app_sak', description: 'Docker image name')
        string(name: 'DOCKER_TAG', defaultValue: "${env.BUILD_ID}", description: 'Docker tag version')
        choice(name: 'DEPLOY_ENV', choices: ['dev', 'prod'], description: 'Deployment environment')
        choice(name: 'ACTION', choices: ['Deploy', 'Remove'], description: 'Remove thed Deployment after testing')
        booleanParam(name: 'CLEANUP', defaultValue: false, description: 'Cleanup Prod resources after deployment')
    }
    environment {
        DOCKER_HUB_CREDENTIALS = 'dockerhub-credentials-id' // Jenkins credential ID
        KUBECONFIG_CREDENTIALS = 'kubeconfig-credentials-id' // Jenkins credential ID
        DOCKER_IMAGE = "${params.DOCKER_IMAGE_NAME}"
        DOCKER_VERSION_TAG = "${params.DOCKER_TAG}"
        DOCKER_LATEST_TAG = "latest"
    }
    stages {
        stage('Build Docker Image') {
            when {
                allOf {
                    expression {
                        params.DEPLOY_ENV == 'prod'
                        params.ACTION == 'Deploy'
                    }
                }
            }
            steps {
                echo 'Building Docker image...'
                sh """
                    sudo docker build -t ${DOCKER_IMAGE}:${DOCKER_VERSION_TAG} .
                """
            }
        }
        stage('Tag Docker Image as Latest') {
            when {
                allOf {
                    expression {
                        params.DEPLOY_ENV == 'prod'
                        params.ACTION == 'Deploy'
                    }
                }
            }
            steps {
                echo 'Tagging Docker image as latest...'
                sh """
                    sudo docker tag ${DOCKER_IMAGE}:${DOCKER_VERSION_TAG} ${DOCKER_IMAGE}:${DOCKER_LATEST_TAG}
                """
            }
        }
        stage('Docker Login') {
            when {
                allOf {
                    expression {
                        params.DEPLOY_ENV == 'prod'
                        params.ACTION == 'Deploy'
                    }
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_HUB_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'sudo docker login -u $DOCKER_USER -p $DOCKER_PASS'
                }
            }
        }

        stage('Push Docker Images') {
            when {
                allOf {
                    expression {
                        params.DEPLOY_ENV == 'prod'
                        params.ACTION == 'Deploy'
                    }
                }
            }
            steps {
                echo 'Pushing Docker images to Docker Hub...'
                sh """
                    sudo docker push ${DOCKER_IMAGE}:${DOCKER_VERSION_TAG}
                    sudo docker push ${DOCKER_IMAGE}:${DOCKER_LATEST_TAG}
                """
            }
        }

        stage('Cleanup Local Docker Images') {
            when {
                allOf {
                    expression {
                        params.DEPLOY_ENV == 'prod'
                        params.ACTION == 'Deploy'
                    }
                }
            }
            steps {
                echo 'Removing local Docker images...'
                sh """
                    sudo docker rmi ${DOCKER_IMAGE}:${DOCKER_VERSION_TAG} || true
                    sudo docker rmi ${DOCKER_IMAGE}:${DOCKER_LATEST_TAG} || true
                """
            }
        }

        stage('Deploy Dev Environment (Docker Compose)') {
            when {
                allOf {
                    expression {
                        params.DEPLOY_ENV == 'dev'
                        params.ACTION == 'Deploy'
                    }
                }
            }
            steps {
                echo 'Deploying Dev environment via Docker Compose...'
                sh 'sudo docker-compose -f docker-compose.yml up -d'
            }
        }

        stage('Remove Dev Environment') {
            when {
                allOf {
                    expression {
                        params.DEPLOY_ENV == 'dev'
                        params.ACTION == 'Remove'
                    }
                }
            }
            steps {
                echo 'Removing Dev environment...'
                sh """
                sudo docker-compose -f docker-compose.yml down --rmi all
                sudo docker system prune -af
                """
            }
        }

        stage('Deploy to Kubernetes (Prod)') {
            when {
                allOf {
                    expression {
                        params.DEPLOY_ENV == 'prod'
                        params.ACTION == 'Deploy'
                    }
                }
            }
            steps {
                withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS}", variable: 'KUBECONFIG_FILE')]) {
                    sh """
                        export KUBECONFIG=$KUBECONFIG_FILE

                        # Deploy MySQL
                        kubectl apply -f k8s_manifest/mysql.yaml
                        kubectl rollout status deployment/mysql -n app-stack

                        # Deploy Nexus
                        kubectl apply -f k8s_manifest/nexus.yaml
                        kubectl rollout status deployment/nexus -n app-stack

                        # Deploy Spring Boot App
                        kubectl apply -f k8s_manifest/spring-app.yaml
                        kubectl rollout status deployment/spring-app -n app-stack
                    """
                }
            }
        }

        stage('Cleanup Prod Kubernetes Resources') {
            when {
                allOf {
                    expression {
                        params.DEPLOY_ENV == 'prod'
                        params.CLEANUP == true
                    }
                }
            }
            steps {
                echo 'Cleaning up Prod resources...'
                withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS}", variable: 'KUBECONFIG_FILE')]) {
                    sh '''
                        export KUBECONFIG=$KUBECONFIG_FILE
                        kubectl delete -f k8s_manifest/spring-app.yaml || true
                        kubectl delete -f k8s_manifest/nexus.yaml || true
                        kubectl delete -f k8s_manifest/mysql.yaml || true
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Logging out from Docker Hub...'
            sh 'sudo docker logout || true'
        }
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}
