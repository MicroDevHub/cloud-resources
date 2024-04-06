# AWS CloudFormation Playbook

## Introduction

This repository provides an Ansible playbook and CloudFormation template for deploying the BookStore application into an AWS development and production environment
## Prerequisites

To run this playbook on your local machine, you must install the following prerequisites:

- Ansible 2.4 or higher
- Python PIP package manager
- The following PIP packages:
    - awscli
    - botocore
    - boto3

You must also configure your local environment with your AWS credentials and you will also need to specify
the ARN of the IAM role that your playbook will use to run provisioning tasks.
Your credentials must have permission to assume this role.

### WSL2 Environment
#### Setting up Ansible on WSL2 with Ubuntu

- Prerequisites

First and foremost, ensure that WSL2 is operational on your machine. If not, refer to this [link](<https://www.notion.so/Setup-WSL-on-Window-5b16441ea01a4d75b5953ea79fd05ca1?pvs=4>) for guidance on setting up WSL2 with Ubuntu.

- Installing Ansible

Install Ansible by executing the following commands in the terminal:

```shell
$ sudo apt update
$ sudo apt install software-properties-common
$ sudo add-apt-repository --yes --update ppa:ansible/ansible
$ sudo apt install ansible
```
- Additionally, install the 'make' package:

```shell
$ sudo apt install make
```

- Install AWS CLI [`LINK`](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

**NOTE**
```
To mitigate security risks associated with the 'ansible.cfg' file in the current directory,
follow the guidelines provided in the Ansible documentation.

If running locally, resolve the issue by exporting:
$ export ANSIBLE_CONFIG=/mnt/d/working/microdevhub/cloud-resources/ansible.cfg
```

## How to add and run a new playbook

### Environment Setup Guide

1. **Review Roles:** Inspect the `roles` folder and adjust or create role templates as needed.
2. **Define Environments:** Define environments in the [`inventory`](./playbooks/inventory) file and [`group_vars`](./playbooks/group_vars) folder. Alternatively, use `make environment/<environment-name>` to set up environments.
3. **Configure IAM Role ARN:** In each environment, configure the IAM role ARN by setting the `Sts.Role` variable in `group_vars/<environment>/vars.yml`.
4. **Create CloudFormation Stack:** Design a CloudFormation stack using a Jinja template located in [`playbooks/templates`](./playbooks/templates).
5. **Create Playbook:** Develop a playbook YAML file in the [`playbooks`](./playbooks) directory.
6. **Configure Environment Settings:** Define environment-specific configuration settings in `group_vars/<environment>/vars.yml` as necessary.
7. **Define Stack Inputs:** If there are stack inputs, specify them in the environment settings file using the syntax `Stack.Inputs.<Parameter>`, e.g., `Stack.Inputs.MyInputParam: some-value`.
8. **Add Make Commands:** Integrate make commands for the new playbook, covering both deployment and deletion.
9. **Deploy/Cleanup:** Ensure to include a command for deploying or deleting the stack, e.g.
     ```
	base-resource/%:
	${INFO} "Deploying base-resource environment $* with Stack.Delete=$(IS_DELETED)..."
	@ ansible-playbook playbooks/base_resource_playbook.yml -e env=$* -e Stack.Delete=$(IS_DELETED) $(FLAGS)
	${INFO} "Deploying base-resource complete"
     ```

   After that, we can use the following command to deploy: `make base-resource/<environment>`.

   OR clean up the resource `make base-resource/<environment> IS_DELETED=TRUE`.

## Conventions

- Environment-specific settings should always be formatted `Config.<Parameter>` (e.g. `Config.VpcName`),
unless you have environment-specific settings for variables related to the roles as defined below

- Variables related to configuring the aws-assume-role are formatted `Sts.<Parameter>` (e.g. `Sts.Role`)

- Variables related to configuring the aws-cloudformation formatted `Stack.<Parameter>` (e.g. `Stack.Name`)

# Additional
- Setup minikube on WSL:
https://gist.github.com/wholroyd/748e09ca0b78897750791172b2abb051