pipeline {
    agent any
    parameters {
        string(name: 'DOCKER_IMAGE_NAME', defaultValue: 'spring_app_sak', description: 'Docker image name')
        string(name: 'DOCKER_TAG', defaultValue: "${env.BUILD_ID}", description: 'Docker tag version')
        choice(name: 'DEPLOY_ENV', choices: ['dev', 'prod'], description: 'Deployment environment')
        booleanParam(name: 'CLEANUP', defaultValue: false, description: 'Cleanup Prod resources after deployment')
    }
    environment {
        DOCKER_HUB_CREDENTIALS = 'dockerhub-credentials-id'
        KUBECONFIG_CREDENTIALS = 'kubeconfig-credentials-id'
        NEXUS_CREDENTIALS = 'nexus-credentials-id'
        DOCKER_IMAGE = "${params.DOCKER_IMAGE_NAME}"
        DOCKER_VERSION_TAG = "${params.DOCKER_TAG}"
        DOCKER_LATEST_TAG = "latest"
    }
    stages {
        stage('Build & Deploy JAR to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${NEXUS_CREDENTIALS}", usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh """
                        docker build --build-arg NEXUS_USER=$NEXUS_USER --build-arg NEXUS_PASS=$NEXUS_PASS -f Dockerfile.build -t ${DOCKER_IMAGE}:${DOCKER_VERSION_TAG}-build .
                    """
                }
            }
        }
        stage('Build Runtime Docker Image') {
            steps {
                sh """
                    docker build -f Dockerfile.runtime -t ${DOCKER_IMAGE}:${DOCKER_VERSION_TAG} .
                    docker tag ${DOCKER_IMAGE}:${DOCKER_VERSION_TAG} ${DOCKER_IMAGE}:${DOCKER_LATEST_TAG}
                """
            }
        }
        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_HUB_CREDENTIALS}", usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'docker login -u $DOCKER_USER -p $DOCKER_PASS'
                }
            }
        }
        stage('Push Docker Images') {
            steps {
                sh """
                    docker push ${DOCKER_IMAGE}:${DOCKER_VERSION_TAG}
                    docker push ${DOCKER_IMAGE}:${DOCKER_LATEST_TAG}
                """
            }
        }
        stage('Deploy to Kubernetes (Prod)') {
            when { expression { params.DEPLOY_ENV == 'prod' } }
            steps {
                withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS}", variable: 'KUBECONFIG_FILE')]) {
                    sh """
                        export KUBECONFIG=$KUBECONFIG_FILE
                        kubectl apply -f k8s_manifest/mysql.yaml
                        kubectl rollout status deployment/mysql -n app-stack
                        
                        kubectl apply -f k8s_manifest/nexus.yaml
                        kubectl rollout status deployment/nexus -n app-stack
                        
                        kubectl apply -f k8s_manifest/spring-app.yaml
                        kubectl rollout status deployment/spring-app -n app-stack
                    """
                }
            }
        }
        stage('Cleanup Prod Resources') {
            when { expression { params.DEPLOY_ENV == 'prod' && params.CLEANUP } }
            steps {
                withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS}", variable: 'KUBECONFIG_FILE')]) {
                    sh """
                        export KUBECONFIG=$KUBECONFIG_FILE
                        kubectl delete -f k8s/spring-app.yaml || true
                        kubectl delete -f k8s/nexus.yaml || true
                        kubectl delete -f k8s/mysql.yaml || true
                    """
                }
            }
        }
    }
    post {
        always {
            sh 'docker logout || true'
        }
    }
}
