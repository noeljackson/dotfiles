.PHONY: all
all: bin dotfiles ## Installs the bin and etc directory files and the dotfiles.

.PHONY: bin
bin: ## Installs the bin directory files.
	# add aliases for things in bin
	sudo mkdir -p /usr/local/bin
	for file in $(shell find $(CURDIR)/bin -type f -not -name "*-backlight" -not -name ".*.swp"); do \
		f=$$(basename $$file); \
		sudo ln -sf $$file /usr/local/bin/$$f; \
	done

.PHONY: clamav
clamav:
	if [ -d "$(shell brew --prefix)/etc/clamav" ]; then \
	for file in $(shell find $(CURDIR)/opt/homebrew/etc/clamav -type f); do \
		f=$$(basename $$file); \
		sudo ln -sf $$file $(shell brew --prefix)/etc/clamav/$$f; \
	done; \
	fi

.PHONY: dotfiles
dotfiles: ## Installs the dotfiles.
	# add aliases for dotfiles
	for file in $(shell find $(CURDIR) -name ".*" -not -name ".gitignore" -not -name ".travis.yml" -not -name ".git" -not -name ".*.swp" -not -name ".gnupg"); do \
		f=$$(basename $$file); \
		ln -snf $$file $(HOME)/$$f; \
	done; \
	gpg --list-keys || true;
	ln -sfn $(CURDIR)/.gnupg/gpg.conf $(HOME)/.gnupg/gpg.conf;
	ln -sfn $(CURDIR)/.gnupg/gpg-agent.conf $(HOME)/.gnupg/gpg-agent.conf;
	# Copy gitignore to ~
	ln -fn $(CURDIR)/gitignore $(HOME)/.gitignore;
	# Copy gitconfig to .gitconfig
	ln -fn $(CURDIR)/gitconfig $(CURDIR)/.gitconfig;
	git update-index --skip-worktree $(CURDIR)/.gitconfig;
	# we use zprofile to source .zshrc
	ln -snf $(CURDIR)/.zprofile $(HOME)/.zprofile;
	ln -snf $(CURDIR)/.zprofile $(HOME)/.zshenv;
	ln -snf $(CURDIR)/.profile $(HOME)/.profile;
	crontab $(CURDIR)/.crontab
	ln -snf $(CURDIR)/.tmux.conf $(HOME)/.tmux.conf;
	

.PHONY: test
test: shellcheck ## Runs all the tests on the files in the repository.

# if this session isn't interactive, then we don't want to allocate a
# TTY, which would fail, but if it is interactive, we do want to attach
# so that the user can send e.g. ^C through.
INTERACTIVE := $(shell [ -t 0 ] && echo 1 || echo 0)
ifeq ($(INTERACTIVE), 1)
	DOCKER_FLAGS += -t
endif

.PHONY: shellcheck
shellcheck: ## Runs the shellcheck tests on the scripts.
	docker run --rm -i $(DOCKER_FLAGS) \
		--name df-shellcheck \
		-v $(CURDIR):/usr/src:ro \
		--workdir /usr/src \
		r.j3ss.co/shellcheck ./test.sh

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
