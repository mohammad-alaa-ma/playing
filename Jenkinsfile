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
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    args: ["--no-push"] # overridden in the steps
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

        stage('Build & Push with Kaniko') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-ecr', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    container('kaniko') {
                        sh """
                        /kaniko/executor \
                          --context ${WORKSPACE} \
                          --dockerfile ${WORKSPACE}/Dockerfile \
                          --destination ${ECR_REPO}:${IMAGE_TAG} \
                          --destination ${ECR_REPO}:latest \
                          --cache=true \
                          --aws-access-key-id=$AWS_ACCESS_KEY_ID \
                          --aws-secret-access-key=$AWS_SECRET_ACCESS_KEY
                        """
                    }
                }
            }
        }
    }
}

