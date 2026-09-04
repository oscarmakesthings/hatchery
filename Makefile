SHELL := /bin/bash

.PHONY: help bootstrap doctor validate

help:
	@printf '%s\n' \
		'Available commands:' \
		'  make help       Show this help.' \
		'  make bootstrap  Configure an Ubuntu 24.04 VPS.' \
		'  make doctor     Check whether Hatchery is ready.' \
		'  make validate   Validate repository shell scripts.'

bootstrap:
	@./scripts/bootstrap.sh

doctor:
	@./scripts/doctor.sh

validate:
	@bash -n scripts/bootstrap.sh scripts/doctor.sh
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck scripts/bootstrap.sh scripts/doctor.sh; \
	else \
		printf '%s\n' 'ShellCheck not installed; skipping ShellCheck.'; \
	fi
