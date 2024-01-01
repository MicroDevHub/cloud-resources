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
Your credentials must have permissions to assume this role.

### WSL2 Environment
#### Setting up Ansible on WSL2 with Ubuntu

#### Prerequisites

First and foremost, ensure that WSL2 is operational on your machine. If not, refer to this [link](<WSL2_SETUP_LINK>) for guidance on setting up WSL2 with Ubuntu.

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

- Install AWS CLI   [`LINK`](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

**NOTE**
To mitigate security risks associated with the 'ansible.cfg' file in the current directory,
follow the guidelines provided in the Ansible documentation.

If running locally, resolve the issue by exporting:
```shell
$ export ANSIBLE_CONFIG=/mnt/d/working/micro-dev-hub/cloud-resources/ansible.cfg
```

## How to add and run a new playbook

1. Review `roles` folder and add or modify an role template if required
2. Define environments in the [`inventory`](./playbooks/inventory) file and [`group_vars`](./playbooks/group_vars) folder.  Alternatively you can use the `make environment/<environment-name>` command.
3. Define a CloudFormation stack name in [`group_vars/all/vars.yml`](./playbooks/group_vars/all/vars.yml) using the `Stack.Name` variable
4. Add the ARN of the IAM role to assume in each environment by configuring the `Sts.Role` variable in `group_vars/<environment>/vars.yml`
5. Define your CloudFormation template in `templates` folder.
6. Define environment-specific configuration settings as required in `group_vars/<environment>/vars.yml`
7. If you have stack inputs, define them using the syntax `Stack.Inputs.<Parameter>` in your environment settings file (e.g. `Stack.Inputs.MyInputParam: some-value`)
8. Deploy your stack by running `make deploy/<environment>` (which executes `ansible-playbook site.yml -e env=<environment>`)

## Conventions

- Environment specific settings should always be formatted `Config.<Parameter>` (e.g. `Config.VpcName`),
unless you have environment specific settings for variables related to the [`aws-sts`](https://github.com/docker-production-aws/aws-sts)
or [`aws-cloudformation`](https://github.com/docker-production-aws/aws-cloudformation) roles as defined below

- Variables related to configuring the aws-assume-role are formatted `Sts.<Parameter>` (e.g. `Sts.Role`)

- Variables related to configuring the aws-cloudformation formatted `Stack.<Parameter>` (e.g. `Stack.Name`)