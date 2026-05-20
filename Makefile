.PHONY: validate

validate:
	nvim --headless -u NONE -l scripts/validate.lua
