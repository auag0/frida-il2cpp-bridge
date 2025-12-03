MAKEFLAGS += --no-builtin-rules
.SUFFIXES:

UNITY_DIRS := $(wildcard unity/*/)

ifeq ($(OS),Windows_NT)
	SHELL := powershell.exe
	REMOVE = Remove-Item -Recurse -Force
	MKDIR = New-Item -ItemType Directory -Force
	TOUCH = powershell -Command "if (-not (Test-Path '$(1)')) { New-Item -ItemType File '$(1)' | Out-Null }; (Get-Item '$(1)').LastWriteTime = Get-Date"
	PYTHON = python
else
	REMOVE = rm -rf
	MKDIR = mkdir -p
	TOUCH = touch -m
	PYTHON = python3
endif

dist: node_modules $(shell find lib) tsconfig.json
	@ npm exec tspc
	@ $(call TOUCH,$@)

node_modules:
	@ npm i
	@ $(TOUCH) "$@"

test: dist test/agent/dist build/host
	@ $(PYTHON) test/main.py

test/agent/dist: node_modules $(shell find test/agent/src) test/agent/tsconfig.json
	@ npm exec tspc -- -p test/agent
	@ $(TOUCH) "$@"

build/host: test/host.c
	@ $(MKDIR) build
	@ gcc -o "$@" "$<"

$(UNITY_DIRS):
	$(MAKE) -C "$@" assembly

assembly: $(UNITY_DIRS);

clean:
	@ $(REMOVE) dist
	@ $(REMOVE) test/agent/dist

.DEFAULT_GOAL := dist
.PHONY: clean test assembly $(UNITY_DIRS)
