# playing



## Step 1: Create EKS Cluster with 2 Nodes

First, let's set up your EKS cluster using AWS CloudShell. We'll use `eksctl` which is pre-installed in CloudShell.
```bash
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz"
tar -xzf eksctl_Linux_amd64.tar.gz
sudo mv eksctl /usr/local/bin
eksctl version
```

### Commands for Step 1:

```bash
# Create EKS cluster with 2 nodes and 20GB storage each
eksctl create cluster \
  --name jenkins-cluster \
  --region us-east-1 \
  --nodegroup-name jenkins-nodes \
  --node-type t3.medium \
  --nodes 2 \
  --nodes-min 2 \
  --nodes-max 2 \
  --node-volume-size 20 \
  --managed
```


### Verify the cluster creation:
```bash
# Check cluster status
eksctl get cluster --name jenkins-cluster --region us-east-1

# Verify nodes
kubectl get nodes
```

==========================================================================================================

Perfect! Let's proceed with **Option A: AWS EBS CSI Driver**.

## Step 2: Install Helm

First, we need to install Helm in your CloudShell environment.

### Commands for Step 2:

```bash
# Download and install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify Helm installation
helm version
```

**Expected output:** You should see Helm version 3.x.x

---

**Please run these commands and confirm:**
1. Helm is installed successfully
2. You can see the version output

Then I'll move to Step 3 (Installing the EBS CSI Driver).







==================================================================================================================================

### ✅ Fix — Create the OIDC provider

Just run this command once for your cluster:

```bash
eksctl utils associate-iam-oidc-provider \
  --region us-east-1 \
  --cluster jenkins-cluster \
  --approve
```

This:

* Creates an **IAM OIDC provider** in your AWS account.
* Links it to your cluster’s identity issuer.
* Enables Kubernetes service accounts in that cluster to assume IAM roles.

---

### 🔁 Then re-run your original command:

```bash
eksctl create iamserviceaccount \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster jenkins-cluster \
  --region us-east-1 \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --role-only \
  --role-name AmazonEKS_EBS_CSI_DriverRole
```


```bash

# Install the EBS CSI Driver addon
eksctl create addon \
  --name aws-ebs-csi-driver \
  --cluster jenkins-cluster \
  --region us-east-1 \
  --service-account-role-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/AmazonEKS_EBS_CSI_DriverRole \
  --force
  
```

```bash

# Check if the CSI driver pods are running
kubectl get pods -n kube-system | grep ebs-csi

# Verify the gp2 StorageClass exists
kubectl get storageclass

```

===============================================================================================================================

Perfect! The EBS CSI driver is running and `gp2` StorageClass is available.

## Step 4: Add Jenkins Helm Repository

Now let's add the official Jenkins Helm repository.

### Commands for Step 4:

```bash
# Add Jenkins Helm repository
helm repo add jenkins https://charts.jenkins.io

# Update Helm repositories
helm repo update

# Verify Jenkins chart is available
helm search repo jenkins
```

**Expected output:** You should see the Jenkins chart listed with its version.


================================================================================================================================


Perfect! That's a practical approach for now.

So we'll:
- ✅ Skip the ServiceAccount with IAM role setup
- ✅ Use IAM user access keys in the pipeline (you'll add them as Jenkins credentials later)
- ✅ Keep things simple

---

## Step 5: Install Jenkins using Helm with your values file

Now let's install Jenkins using your `jenkins-values.yaml` file.

### Commands for Step 5:

```bash
# Create a namespace for Jenkins
kubectl create namespace jenkins

# Install Jenkins using your values file
helm install jenkins jenkins/jenkins \
  --namespace jenkins \
  --values jenkins-values.yaml

# Wait for Jenkins to be ready (this may take 2-3 minutes)
kubectl get pods -n jenkins -w
```

**Note:** Press `Ctrl+C` to stop watching once the pod shows `Running` status.

### Get the initial admin password:
```bash
# Get Jenkins admin password
kubectl exec -n jenkins -it svc/jenkins -c jenkins -- cat /run/secrets/additional/chart-admin-password && echo
```

vHa6SoiMIAsq7OFdqi0Yn2

### Get the NodePort access:
```bash
# Get the node external IP
kubectl get nodes -o wide

# Confirm NodePort
kubectl get svc -n jenkins
```
>>>>>>>>>>>>>>>>>>>>>> allow inbound for the security group attached to nodes
**You should access Jenkins at:** `http://<NODE_EXTERNAL_IP>:32000`

---

**Please run these commands and let me know:**
1. Is the Jenkins pod running?
2. Can you retrieve the admin password?
3. Can you see the node's external IP?

Then I'll guide you on accessing Jenkins UI and setting up your pipeline with ECR credentials!



>>>>>>>>>>>>>>>>>>>> add "GitHub" plugin to jenkins

>>>>>>>>>>>>>>>>>>>> create user having ecr access then get it access key and secret access key

>>>>>>>>>>>>>>>>>>>> go to credentials -> system (global) -> global credentials -> Add credentials -> access and seceret and ID as aws-ecr (must for pipeline)

=======================================================================================================================

Excellent! Your pipeline looks good. Now let's add the AWS credentials to Jenkins.

## Step 6: Add AWS Credentials to Jenkins

You'll add your IAM user's Access Key and Secret Key as Jenkins credentials with ID `aws-ecr` (as referenced in your pipeline).

### Steps to add credentials in Jenkins UI:

1. **Access Jenkins UI:**
   - Go to `http://<NODE_EXTERNAL_IP>:32000`
   - Login with username `admin` and the password you retrieved earlier

2. **Navigate to Credentials:**
   - Click on **"Manage Jenkins"** (left sidebar)
   - Click on **"Credentials"**
   - Click on **"System"** 
   - Click on **"Global credentials (unrestricted)"**
   - Click on **"Add Credentials"** (left sidebar)

3. **Add AWS Credentials:**
   - **Kind:** Select `Username with password`
   - **Scope:** `Global`
   - **Username:** Paste your `AWS_ACCESS_KEY_ID`
   - **Password:** Paste your `AWS_SECRET_ACCESS_KEY`
   - **ID:** Type exactly `aws-ecr` (this must match your pipeline)
   - **Description:** `AWS ECR Credentials` (optional)
   - Click **"Create"**

---

### Verify your IAM user has ECR permissions:

Your IAM user needs this policy attached:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload"
            ],
            "Resource": "*"
        }
    ]
}
```

---

**Please confirm:**
1. Have you added the credentials with ID `aws-ecr` in Jenkins?
2. Does your IAM user have the necessary ECR permissions?

Then I'll guide you to create your pipeline job and test it!


===========================================================================================================

Perfect! Here's the simple command:

### Step 8: Create ECR Repository (Simple)

Run this in your AWS CloudShell:

```bash
# Create ECR repository named 'playing' (simple version)
aws ecr create-repository \
    --repository-name playing \
    --region us-east-1

# Verify the repository was created
aws ecr describe-repositories --repository-names playing --region us-east-1
```

**Expected output:** You'll see the repository URI: `609854511954.dkr.ecr.us-east-1.amazonaws.com/playing`

---

**Please confirm:**
1. ECR repository created successfully?

Then you can update your Jenkins pipeline with the filtered version and test it!


=============================================================================================================


make changes in dockerfile or code directory

it will build and succeed

then 
>>>>>>>>>>>>>>> to register to ecr
aws ecr get-login-password --region us-east-1 \
  | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com

>>>>>>>>>>>>> pull the image 
docker pull $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com/playing:latest

>>>>>>>>>>>>>>>>>>>>>> run it to check

docker run -d -p 3000:3000 609854511954.dkr.ecr.us-east-1.amazonaws.com/playing:latest

curl localhost:3000






















@@@@@@@@@@@@@@@@@@@@@@@@@@ old working pipeline @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

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




~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


~ $ cat jenkins-values.yaml 
controller:
  serviceAccount:
    create: false
    name: jenkins
  
  installPlugins:
    - kubernetes:latest
    - workflow-aggregator:latest
    - git:latest
    - configuration-as-code:latest
  
  serviceType: NodePort
  nodePort: 32000
  
agent:
  podName: "jenkins-agent"
  
persistence:
  enabled: true
  size: 8Gi
  storageClass: gp2











