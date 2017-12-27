
.PHONY: new-version

all:
	@echo
	@echo "Commands: "
	@echo " - new-version: add a new version (this will add git tag)"
	@echo

new-version:
	@cd misc ; \
	bash new-version.sh
