SHELL := /bin/bash

.PHONY: check

check:
	@set -e; \
	for f in $$(find linux -name '*.sh'); do bash -n "$$f"; done; \
	sh -n linux/chezmoi/dot_profile; \
	sh -n linux/chezmoi/dot_config/shell/env.sh; \
	if command -v zsh >/dev/null 2>&1; then \
		zsh -n linux/chezmoi/dot_config/zsh/dot_zshrc; \
		zsh -n linux/chezmoi/dot_zshenv; \
	fi; \
	for f in $$(find linux/chezmoi -name '*.fish'); do fish --no-execute "$$f"; done; \
	for f in $$(find linux/chezmoi/dot_config/dms -maxdepth 2 -name '*.json'); do \
		python3 -m json.tool "$$f" >/dev/null; \
	done; \
	python3 -m json.tool linux/archinstall-no_disk_user.json >/dev/null; \
	python3 -B -c 'import ast; ast.parse(open("linux/system/apply.py").read())'; \
	python3 -B -c 'import ast; ast.parse(open("linux/system/hostinfo.py").read())'; \
	python3 -c 'import pathlib,tomllib; [tomllib.load(open(p,"rb")) for p in [pathlib.Path("linux/chezmoi/.chezmoidata/hosts.toml"), pathlib.Path("linux/system/manifest.toml"), *pathlib.Path("linux/system/manifests").rglob("*.toml")]]'; \
	tmp=$$(mktemp -d); \
	trap 'rm -rf "$$tmp"' EXIT; \
	if command -v niri >/dev/null 2>&1; then \
		cp linux/chezmoi/dot_config/niri/config.kdl \
		   linux/chezmoi/dot_config/niri/binds.kdl "$$tmp/"; \
		cp linux/chezmoi/dot_config/niri/shells/dms.kdl "$$tmp/shell.kdl"; \
		: > "$$tmp/outputs.kdl"; \
		niri validate -c "$$tmp/config.kdl" >/dev/null 2>&1; \
	fi; \
	if command -v umbriel >/dev/null 2>&1; then \
		rm -rf "$$tmp"/*; \
		cp linux/chezmoi/dot_config/umbriel/config.toml \
		   linux/chezmoi/dot_config/umbriel/keybinds-common.toml \
		   linux/chezmoi/dot_config/umbriel/keybinds-dms.toml \
		   linux/chezmoi/dot_config/umbriel/keybinds-noctalia.toml "$$tmp/"; \
		printf '[include]\nfiles = ["keybinds-common.toml", "keybinds-noctalia.toml"]\n\n[general]\nautostart = ["noctalia"]\n' > "$$tmp/shell.toml"; \
		printf '[output.eDP-1]\nmode = "1920x1200@60"\nposition = [0, 0]\nscale = 1.0\n' > "$$tmp/outputs.toml"; \
		umbriel config validate -c "$$tmp/config.toml" >/dev/null; \
	fi; \
	if command -v noctalia >/dev/null 2>&1; then \
		noctalia config validate "$$PWD/linux/chezmoi/dot_config/noctalia/config.toml" >/dev/null; \
	fi; \
	if command -v basrs >/dev/null 2>&1; then \
		basrs source linux/chezmoi/dot_config/shell/aliases.sh | grep -q '^alias dyff '; \
	fi; \
	echo "checks passed"
