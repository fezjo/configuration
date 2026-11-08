SHELL := /bin/bash

.PHONY: check
check:
	@set -e; \
	for f in $$(find linux -name '*.sh' -o -name 'setup.sh'); do bash -n "$$f"; done; \
	sh -n linux/chezmoi/dot_profile; \
	sh -n linux/chezmoi/dot_config/shell/env.sh; \
	zsh -n linux/chezmoi/dot_config/zsh/dot_zshrc; \
	zsh -n linux/chezmoi/dot_zshenv; \
	for f in $$(find linux/chezmoi -name '*.fish'); do fish --no-execute "$$f"; done; \
	python3 -m json.tool linux/archinstall-no_disk_user.json >/dev/null; \
	python3 -B -c 'import ast; ast.parse(open("linux/system/apply.py").read())'; \
	if command -v niri >/dev/null 2>&1; then \
		tmp=$$(mktemp -d); \
		cp linux/chezmoi/dot_config/niri/config.kdl "$$tmp/config.kdl"; \
		ln -s "$$HOME/.config/niri/dms" "$$tmp/dms"; \
		niri validate -c "$$tmp/config.kdl" >/dev/null 2>&1; \
		rm -rf "$$tmp"; \
	fi; \
	echo "checks passed"
