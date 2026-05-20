.PHONY: validate test test-runner format format-check check

validate:
	nvim --headless -u NONE -l scripts/validate.lua

test:
	nvim --headless -u NONE -l scripts/test.lua

test-runner:
	nvim --headless -u NONE -l scripts/test_runner.lua

format:
	stylua lua scripts

format-check:
	stylua --check lua scripts

check: format-check validate test test-runner
