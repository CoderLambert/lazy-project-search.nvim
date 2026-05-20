.PHONY: validate test check

validate:
	nvim --headless -u NONE -l scripts/validate.lua

test:
	nvim --headless -u NONE -l scripts/test.lua

check: validate test
