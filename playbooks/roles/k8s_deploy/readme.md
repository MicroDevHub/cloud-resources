# EKS Deploy Role
## Overview
The EKS Deploy role is designed to facilitate the deployment of services onto Amazon Elastic Kubernetes Service (EKS) using Ansible. This README provides an overview of the role's functionality and how to use it effectively.

## Purpose
The role serves as part of a Kubernetes deployment playbook, enabling seamless deployment and management of services within an EKS environment. It automates various tasks involved in the deployment process, making it easier to deploy new versions or update configurations.

## Usage

To deploy a service onto EKS using this role, follow these steps:

1. Trigger Deployment: Execute the make command `k8s-deployment/{env}` to initiate the deployment process. Replace {env} with the desired environment, such as dev, stage, or prod.
2. Initialization Step:
- Installs required packages/modules for Ansible to work with Kubernetes.
- Creates a namespace based on the configuration specified in the playbook.
3. Configuration Read:
- Reads service configurations from the catalog folder under the apps directory.
- Reads configuration maps from the configurations directory within the catalog folder.
- Utilizes these configurations to generate deployment files based on Jinja templates.
Generated templates are stored under the deployments folder within the catalog directory.
4. Deployment Application:
- Utilizes the generated deployment files to deploy services, config maps, and deployments onto Kubernetes.
- Applies the configurations to the EKS cluster.
- Compares existing resources on EKS with configurations in the catalog.
Removes any resources from EKS that are not present in the catalog configurations.
5. Deletion Process:
- If the **deleted_namespace** flag is set to false during playbook execution, a deletion namespace process is triggered.
# Note
- Ensure that the **deleted_namespace** flag is set appropriately during playbook execution to control whether deployment or deletion processes are performed.
- It's recommended to review and verify configurations in the catalog directory before initiating deployment to avoid unintended resource deletion.
- For detailed configuration options and customization, refer to the playbook and associated configuration files.
# Contributing
Feel free to contribute to the improvement and enhancement of this role. Pull requests are welcome!

# Additional
- Setup minikube on WSL:
https://gist.github.com/wholroyd/748e09ca0b78897750791172b2abb051