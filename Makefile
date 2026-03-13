.PHONY: help setup config tunnel backup

CONOHA_HOST  ?=
GOGOCOIN_DIR ?= ../gogocoin
SSH_KEY      ?= ~/.ssh/gogocoin
BACKUP_DIR   := ./backup

.DEFAULT_GOAL := help

# Help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

# Setup
setup: ## Transfer setup.sh and gogocoin.service to VPS and run setup
	@[ -n "$(CONOHA_HOST)" ] || { echo "Error: CONOHA_HOST is not set. Usage: make setup CONOHA_HOST=<VPS_IP>"; exit 1; }
	scp -i $(SSH_KEY) setup.sh gogocoin.service root@$(CONOHA_HOST):/tmp/
	ssh -i $(SSH_KEY) root@$(CONOHA_HOST) "cd /tmp && bash setup.sh"

# Config
config: ## Transfer config.yaml from gogocoin repo to VPS (usage: make config GOGOCOIN_DIR=../gogocoin)
	@[ -n "$(CONOHA_HOST)" ] || { echo "Error: CONOHA_HOST is not set. Usage: make config CONOHA_HOST=<VPS_IP>"; exit 1; }
	@[ -f "$(GOGOCOIN_DIR)/configs/config.yaml" ] || { echo "Error: $(GOGOCOIN_DIR)/configs/config.yaml not found."; exit 1; }
	scp -i $(SSH_KEY) $(GOGOCOIN_DIR)/configs/config.yaml root@$(CONOHA_HOST):/opt/gogocoin/configs/config.yaml
	ssh -i $(SSH_KEY) root@$(CONOHA_HOST) "chown gogocoin:gogocoin /opt/gogocoin/configs/config.yaml && chmod 640 /opt/gogocoin/configs/config.yaml && ([ -f /opt/gogocoin/gogocoin ] && systemctl restart gogocoin && echo 'Service restarted.' || echo 'Binary not deployed yet. Skipping restart.')"

# SSH tunnel
tunnel: ## Open SSH tunnel to WebUI (http://localhost:8080)
	@[ -n "$(CONOHA_HOST)" ] || { echo "Error: CONOHA_HOST is not set. Usage: make tunnel CONOHA_HOST=<VPS_IP>"; exit 1; }
	ssh -i $(SSH_KEY) -L 8080:localhost:8080 -N root@$(CONOHA_HOST)

# Backup
backup: ## Download logs and DB from VPS to ./backup/<timestamp>/
	@[ -n "$(CONOHA_HOST)" ] || { echo "Error: CONOHA_HOST is not set. Usage: make backup CONOHA_HOST=<VPS_IP>"; exit 1; }
	$(eval DEST := $(BACKUP_DIR)/$(shell date +%Y%m%d_%H%M%S))
	@mkdir -p $(DEST)/logs $(DEST)/data
	rsync -az -e "ssh -i $(SSH_KEY)" root@$(CONOHA_HOST):/opt/gogocoin/logs/ $(DEST)/logs/
	rsync -az -e "ssh -i $(SSH_KEY)" root@$(CONOHA_HOST):/opt/gogocoin/data/ $(DEST)/data/
	@echo "Backup saved to $(DEST)"
