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
