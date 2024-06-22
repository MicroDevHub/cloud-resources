# Overview

The document provides a guide on using Amazon Elastic Kubernetes Service (EKS) and Amazon Elastic Container Registry (ECR) to pull and create images. It details the process of pushing an Nginx image to ECR, and configuring the catalog to deploy it to either EKS or Minikube. It also outlines how to create an ECR repository and access it from Minikube and EKS. The guide provides two methods for EKS to authenticate with ECR: using IAM Roles for Service Accounts (IRSA) or manually creating image pull secrets.

## Creating an ECR Repository

To create an Amazon ECR repository and gain access to it locally using AWS ECR, you can use Docker commands to push an image to the ECR repository. Detailed instructions for this process can be found at https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-push-ecr-image.html. Below is an example of how to push an nginx image to ECR.

```bash
#!/bin/bash
# Variables
REGION="us-east-1"
ACCOUNT_ID="123456789012"
REPOSITORY_NAME="my-nginx-repo"

# Tag the Nginx image
docker tag nginx:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:latest

# Push the image to ECR
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPOSITORY_NAME:latest

# Check if push was successful
if [ $? -eq 0 ]; then
  echo "Successfully pushed the Nginx image to ECR"
else
  echo "Failed to push the Nginx image to ECR"
  exit 1
fi

```

## Accessing ECR from Minikube

If you are using Minikube locally, you'll need to set up ECR credentials for Minikube to pull the image from ECR. This involves using the AWS CLI to get the ECR login password and creating a Kubernetes secret that stores these credentials. You'll then have to configure your Kubernetes deployment to use the secret for pulling images.

### Detailed Steps

- Step 1: Get ECR Login Password
    
    Use the following command to get the ECR login password and create a Docker configuration file:
    
    ```bash
    aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin 236925568009.dkr.ecr.ap-southeast-2.amazonaws.com
    ```
    
- Step 2: Create a Kubernetes Secret
    
    Create a Kubernetes secret with the ECR credentials. First, generate a Docker configuration JSON:
    
    - Save Docker credentials to a file
    
    `cat ~/.docker/config.json`
    Use the contents of the ~/.docker/config.json file to create a Kubernetes secret:
    
    ```bash
    kubectl create secret generic ecr-secret --from-file=.dockerconfigjson=/path/to/your/config.json --type=kubernetes.io/dockerconfigjson --namespace <your-namespace>
    ```
    
    Verify the ecr-secret exists in the same namespace as your deployment:
    
    ```bash
    kubectl get secrets --namespace <your-namespace>
    ```
    
- Step 3: Configure Your Kubernetes Deployment
    
    Update your Kubernetes deployment YAML to use the created secret. Add the imagePullSecrets section to the deployment spec, e.g:
    
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: bookstore-service
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: bookstore-service
      template:
        metadata:
          labels:
            app: bookstore-service
        spec:
          containers:
          - name: bookstore-service
            image: 236925568009.dkr.ecr.ap-southeast-2.amazonaws.com/microdevhub/bookstore-service:latest
            ports:
            - containerPort: 80
          imagePullSecrets:
          - name: ecr-secret
    ```
    

### Summary

By following these steps, you ensure that Minikube can authenticate with ECR and pull the required images. This setup involves creating a Docker configuration file with ECR credentials, converting it into a Kubernetes secret, and configuring your Kubernetes deployments to use this secret for image pulls.

## Accessing ECR from EKS

If you're using Amazon Elastic Kubernetes Service (EKS) instead of Minikube, you need to follow a slightly different process to ensure your EKS cluster can authenticate with Amazon ECR to pull images. EKS supports integrating with ECR using IAM roles for service accounts (IRSA) or by manually creating image pull secrets.

Here’s a step-by-step guide to configuring your EKS cluster to pull images from ECR using both methods:

configure (EKS) cluster to authenticate with Amazon ECR and pull images. Both methods are flexible and can cater to different use cases. The choice between the two depends on your project’s requirements and your personal preferences. However, using IRSA is generally recommended for its superior security and manageability.

### Method 1: Using IAM Roles for Service Accounts (IRSA)

IRSA allows EKS to assume IAM roles to access AWS resources, including ECR. This is the recommended method because it provides better security and manageability.

- Step 1: Create an IAM Policy for ECR Access and Create an IAM role and attach the policy you just created. Make sure the role can be assumed by the EKS service account.
    
    Create an IAM policy that allows ECR access:
    
    ```yaml
    AWSTemplateFormatVersion: '2010-09-09'
    Resources:
      ECRReadAccessPolicy:
        Type: 'AWS::IAM::Policy'
        Properties:
          PolicyName: 'ECRReadAccessPolicy'
          PolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: 'Allow'
                Action:
                  - 'ecr:GetDownloadUrlForLayer'
                  - 'ecr:BatchGetImage'
                  - 'ecr:BatchCheckLayerAvailability'
                  - 'ecr:GetAuthorizationToken'
                Resource: '*'
          Roles:
            - !Ref ECRReadOnlyRole
    
      ECRReadOnlyRole:
        Type: 'AWS::IAM::Role'
        Properties:
          RoleName: 'ECRReadOnlyRole'
          AssumeRolePolicyDocument:
            Version: '2012-10-17'
            Statement:
              - Effect: 'Allow'
                Principal:
                  Service: 'eks.amazonaws.com'
                Action: 'sts:AssumeRole'
          Path: '/'
    
    Outputs:
      RepositoryUri:
        Description: 'The URI of the ECR repository'
        Value: !GetAtt ECRRepository.RepositoryUri
    
      ECRRoleArn:
        Description: 'The ARN of the ECR read-only IAM role'
        Value: !GetAtt ECRReadOnlyRole.Arn
    
    ```
    
- Step 2: Annotate the Kubernetes Service Account
    
    Annotate your Kubernetes service account to use the IAM role:
    
    ```bash
    kubectl annotate serviceaccount ecr-access-sa \\
        -n default \\
        eks.amazonaws.com/role-arn=arn:aws:iam::<your-account-id>:role/<your-role-name>
    
    ```
    
    Replace <your-account-id> and <your-role-name> with your actual AWS account ID and the IAM role name created by eksctl.
    
- Step 3: Deploy Your Application Using the Service Account
    
    Update your deployment to use the service account:
    
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: bookstore-service
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: bookstore-service
      template:
        metadata:
          labels:
            app: bookstore-service
        spec:
          serviceAccountName: ecr-access-sa
          containers:
          - name: bookstore-service
            image: 236925568009.dkr.ecr.ap-southeast-2.amazonaws.com/microdevhub/bookstore-service:latest
            ports:
            - containerPort: 80
    ```
    

### Method 2: Manually Creating Image Pull Secrets

If you prefer not to use IRSA, you can create image pull secrets manually.

- Step 1: Get ECR Login Password
    
    Get the ECR login password and create a Docker configuration file:
    
    ```bash
    aws ecr get-login-password --region ap-southeast-2 | docker login --username AWS --password-stdin 236925568009.dkr.ecr.ap-southeast-2.amazonaws.com
    ```
    
- Step 2: Create a Kubernetes Secret
    
    Create a Kubernetes secret in your EKS cluster:
    
    ```bash
    kubectl create secret docker-registry ecr-secret \\
        --docker-server=236925568009.dkr.ecr.ap-southeast-2.amazonaws.com \\
        --docker-username=AWS \\
        --docker-password=$(aws ecr get-login-password --region ap-southeast-2) \\
        --docker-email=<your-email>\\
    ```
    
- Step 3: Deploy Your Application Using the Secret
    
    Update your deployment to use the image pull secret:
    
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: bookstore-service
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: bookstore-service
      template:
        metadata:
          labels:
            app: bookstore-service
        spec:
          containers:
          - name: bookstore-service
            image: 236925568009.dkr.ecr.ap-southeast-2.amazonaws.com/microdevhub/bookstore-service:latest
            ports:
            - containerPort: 80
          imagePullSecrets:
          - name: ecr-secret
    ```
    

### Summary

By using either IAM Roles for Service Accounts (IRSA) or manually creating image pull secrets, you can configure your EKS cluster to authenticate and pull images from ECR securely. IRSA is the preferred method due to its security and ease of management. However, the manual method is also viable if you need a quicker setup or have specific requirements.