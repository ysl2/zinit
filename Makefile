.EXPORT_ALL_VARIABLES:

ZSH := $(shell command -v zsh 2> /dev/null)
SRC := zinit{'','-additional','-autoload','-install','-side'}.zsh
DOC_SRC := $(foreach wrd,$(SRC),../$(wrd))

.PHONY: all clean container doc doc/container tags tags/emacs tags/vim test zwc

clean:
	rm -rvf *.zwc doc/zsdoc/zinit{'','-additional','-autoload','-install','-side'}.zsh.adoc doc/zsdoc/data/

container-build:
	docker buildx build \
		--load \
		--platform linux/amd64 \
		--progress plain \
		--pull \
		--tag ghcr.io/zdharma-continuum/zinit:latest \
		.

container-run:
	docker run \
		--hostname zinit-docker \
		--interactive \
		--mount source=zinit-docker-volume,destination=/home \
		--platform linux/amd64 \
		--security-opt seccomp=unconfined \
		--tty \
		ghcr.io/zdharma-continuum/zinit:latest

# (\#*FUNCTION:[[:space:]][\:\-\.\+\@\-a-zA-Z0-9]*[\[]*|}[[:space:]]\#[[:space:]][\]]*)
doc: clean
	cd doc; zsh -l -d -f -i -c "zsd -v --scomm --cignore '(\#[[:space:]]FUNCTION:[[:space:]][\_\+\-\.\:\@a-zA-Z0-9]*[[:space:]][\[]*|\#\s[\]]*)' $(DOC_SRC)"

doc/container: container
	./scripts/docker-run.sh --docs --debug

tags: tags/emacs tags/vim  ## Run ctags to generate Emacs and Vim's format tag file.

tags/emacs: ## Build Emacs-style ctags file
	@if type ctags >/dev/null 2>&1; then \
		if ctags --version | grep >/dev/null 2>&1 "Universal Ctags"; then \
			ctags --languages zsh --maxdepth 1 --options share/zsh.ctags --pattern-length-limit 250 -R -e; \
		else \
			ctags --langmap sh:.zsh --languages sh -R -e; \
		fi; \
		echo "==> Created Emac 'TAGS' file"; \
	else \
	    echo "Error: No Ctags version (exuberant or universal) version found"; \
	fi

tags/vim: ## Build the Vim-style ctags file
	@if type ctags >/dev/null 2>&1; then \
		if ctags --version | grep >/dev/null 2>&1 "Universal Ctags"; then \
			ctags --languages zsh --maxdepth 1 --options share/zsh.ctags --pattern-length-limit 250 -R; \
		else \
			ctags --langmap sh:.zsh --languages sh -R; \
		fi; \
		echo "==> Created Vim 'TAGS' file"; \
	else \
	    echo "Error: No Ctags version (exuberant or universal) version found"; \
	fi

test:
	zunit run

zwc:
	$(or $(ZSH),:) -fc 'for f in *.zsh; do zcompile -R -- $$f.zwc $$f || exit; done'
