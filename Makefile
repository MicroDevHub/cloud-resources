# Deployment flags
FLAGS = $(ROLLBACK_FLAG) $(POLICY_FLAG) $(DEBUG_FLAG) $(VERBOSE_FLAG) $(CODEBUILD_FLAG)
ROLLBACK_FLAG = $(if $(findstring /disable_rollback,$(ARGS)),-e 'Stack.DisableRollback=true',)
POLICY_FLAG = $(if $(findstring /disable_policy,$(ARGS)),-e 'Stack.DisablePolicy=true',)
DEBUG_FLAG = $(if $(findstring /debug,$(ARGS)),-e 'debug=true',)
VERBOSE_FLAG = $(if $(findstring /verbose,$(ARGS)),-vvv,)
CODEBUILD_FLAG = $(if $(findstring /codebuild,$(ARGS)),-e 'Stack.BuildFolder=build',)

include Makefile.settings

.PHONY: roles environment generate deploy delete

# This step will automatically create a new group_vars
# eg command: make environment/npr
environment/%:
	@ mkdir -p playbooks/group_vars/$*
	@ touch playbooks/group_vars/$*/vars.yml
	@ echo >> playbooks/inventory
	@ echo '[$*]' >> playbooks/inventory
	@ echo '$* ansible_connection=local' >> playbooks/inventory
	${INFO} "Created environment $*"

generate/%:
	${INFO} "Generating templates for $*..."
	@ ansible-playbook playbooks/base_resource_playbook.yml -e env=$* $(FLAGS) --tags generate -e debug=true
	${INFO} "Generation complete"

base-resource/%:
	${INFO} "Deploying base-resource environment $* with Stack.Delete=$(IS_DELETED)..."
	@ ansible-playbook playbooks/base_resource_playbook.yml -e env=$* -e Stack.Delete=$(IS_DELETED) $(FLAGS)
	${INFO} "Deploying base-resource complete"

ecr-resource/%:
	${INFO} "Deploying ecr-resource environment $* with Stack.Delete=$(IS_DELETED)..."
	@ ansible-playbook playbooks/ecr_playbook.yml -e env=$* -e Stack.Delete=$(IS_DELETED) $(FLAGS)
	${INFO} "Deploying ecr-resource complete"

vpc-resource/%:
	${INFO} "Deploying vpc-resource environment $* with Stack.Delete=$(IS_DELETED)..."
	@ ansible-playbook playbooks/vpc_playbook.yml -e env=$* -e Stack.Delete=$(IS_DELETED) $(FLAGS)
	${INFO} "Deploying vpc-resource complete"

eks-resource/%:
	${INFO} "Deploying eks-resource environment $* with Stack.Delete=$(IS_DELETED)..."
	@ ansible-playbook playbooks/eks_playbook.yml -e env=$* -e Stack.Delete=$(IS_DELETED) $(FLAGS)
	${INFO} "Deploying eks-resource complete"

k8s-deployment/%:
	${INFO} "Deploying services to K8S for the '$(if $(strip $(NAMESPACE)),$(NAMESPACE),$*)' namespace in '$*' env with Stack.DELETED_NAMESPACE=$(DELETED_NAMESPACE).."
	@ ansible-playbook playbooks/k8s_app_deploy_playbook.yml -e env=$* -e Stack.Namespace=$(NAMESPACE) -e Stack.DeletedNamespace=$(DELETED_NAMESPACE) $(FLAGS)
	${INFO} "Deploying services to K8S complete"

#----------------------------------------------------------------------------------------#
# Install the AWS Load Balancer Controller using Helm
alb-ingress-controlle-resource/%:
	${INFO} "Deploying alb to K8S in '$*' env.."
	@ ansible-playbook playbooks/alb_ingress_controller_playbook.yml -e env=$* $(FLAGS)
	${INFO} "Deploying alb to K8S complete"

alb-ingress-controller-init-resource/%:
	${INFO} "Create IAM role for alb to K8S in '$*' env.."
	@ ansible-playbook playbooks/alb_ingress_controller_init_playbook.yml -e env=$* $(FLAGS)
	${INFO} "Create IAM role for to K8S complete"
#----------------------------------------------------------------------------------------#

#----------------------------------------------------------------------------------------#
#  For the AWS user’s to interact with the cluster, you need to edit the aws-auth ConfigMap,
#  and create the roles/clusterroles and rolebindings/clusterrolebindings with the group that you will specify in the aws-auth.
k8s-admin-role-resource/%:
	${INFO} "Add KubeAdmin role to mapRoles K8s in '$*' env.."
	@ ansible-playbook playbooks/kubeadmin_role_playbook.yml -e env=$* $(FLAGS)
	${INFO} "Add KubeAdmin role to mapRoles K8s complete"

k8s-admin-role-init-resource/%:
	${INFO} "Creating a Admin role to access K8S cluster in '$*' env.."
	@ ansible-playbook playbooks/kubeadmin_role_init_playbook.yml -e env=$* $(FLAGS)
	${INFO} "Creating a Admin role to access K8S cluster complete"
#----------------------------------------------------------------------------------------#