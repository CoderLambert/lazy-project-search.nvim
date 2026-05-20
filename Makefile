.PHONY: validate test test-runner check

validate:
	nvim --headless -u NONE -l scripts/validate.lua

test:
	nvim --headless -u NONE -l scripts/test.lua

test-runner:
	nvim --headless -u NONE -l scripts/test_runner.lua

check: validate test test-runner
