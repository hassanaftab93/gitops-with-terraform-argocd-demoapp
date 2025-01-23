.PHONY: tfinit
tfinit:
	terraform init -upgrade

.PHONY: tfvalidate
tfvalidate: tfinit
	terraform validate

.PHONY: tfplan
tfplan: tfvalidate
	mkdir -p ./plans
	terraform plan -out=./plans/plan.tfplan

.PHONY: tfapply
tfapply: tfplan
	terraform apply ./plans/plan.tfplan

MAKEFLAGS += --silent