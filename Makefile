SHELL := /bin/bash

.PHONY: help bootstrap doctor validate

help:
	@printf '%s\n' \
		'Available commands:' \
		'  make help       Show this help.' \
		'  make bootstrap  Configure an Ubuntu 24.04 VPS.' \
		'  make doctor     Check whether Hatchery is ready.' \
		'  make validate   Check shell scripts and run isolated behavioral tests.'

bootstrap:
	@./scripts/bootstrap.sh

doctor:
	@./scripts/doctor.sh

validate:
	@for script in scripts/*.sh tests/*.sh; do bash -n "$$script" || exit; done
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck scripts/*.sh tests/*.sh; \
	else \
		printf '%s\n' 'ShellCheck not installed; skipping ShellCheck.'; \
	fi
	@bash tests/behavior.sh
