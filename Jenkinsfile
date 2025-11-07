pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins
  containers:
  - name: jnlp
    image: jenkins/inbound-agent:latest-jdk17
    tty: true
  - name: docker
    image: docker:24.0.5-dind
    securityContext:
      privileged: true
    tty: true
"""
        }
    }
    environment {
        ECR_REPO = '609854511954.dkr.ecr.us-east-1.amazonaws.com/playing'
        AWS_REGION = 'us-east-1'
        IMAGE_TAG = "${BUILD_NUMBER}"
    }
    stages {
        stage('Clone Repository') {
            steps {
                git branch: 'main', url: 'https://github.com/mohammad-alaa-ma/playing.git'
            }
        }
        
        stage('Check Changes') {
            steps {
                script {
                    def changes = sh(
                        script: 'git diff --name-only HEAD~1 HEAD || echo "Dockerfile"',
                        returnStdout: true
                    ).trim()
                    
                    echo "Changed files: ${changes}"
                    
                    if (!changes.contains('Dockerfile') && !changes.contains('nodeapp/')) {
                        currentBuild.result = 'SUCCESS'
                        error('No relevant files changed. Skipping build.')
                    }
                    
                    echo "Relevant files changed. Proceeding with build."
                }
            }
        }
        
        stage('Build & Push Docker Image') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: 'aws-ecr', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh '''
# Install AWS CLI dynamically
apk add --no-cache python3 py3-pip bash
pip3 install --upgrade pip
pip3 install awscli
# Configure AWS CLI
aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
aws configure set default.region $AWS_REGION
# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO
# Build and push Docker image
docker build -t $ECR_REPO:$IMAGE_TAG .
docker tag $ECR_REPO:$IMAGE_TAG $ECR_REPO:latest
docker push $ECR_REPO:$IMAGE_TAG
docker push $ECR_REPO:latest
                        '''
                    }
                }
            }
        }
    }
}
