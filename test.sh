#!/bin/bash

set -e

export PATH=./tests/hello:$PATH

green() { echo -e "\033[32m$*\033[0m"; }
red()   { echo -e "\033[31m$*\033[0m"; }

run_test() {
  local description="$1"
  local cmd="$2"
  local expected="$3"

  # Run the command and capture all its output
  local actual
  actual=$(eval "$cmd")

  if [[ "$actual" == "$expected" ]]; then
    green "[pass] $description"
    return 0
  else
    red "[fail] $description: expected '$expected', got '$actual'"
    return 1
  fi
}

run_test \
  "1: Arg with space" \
  "hello \"world is my toilet\"" \
  "hello world is my toilet"

run_test \
  "2: Subcommand 'world' with args" \
  "hello world is the default" \
  "HELLO WORLD is the default"

run_test \
  "3: Subcommand 'universe', which doesn't exist so falls back to hello" \
  "hello universe" \
  "hello universe"

run_test \
  "4: Files subcommand with flag" \
  "hello file contents -f README.md | head -n1" \
  "# subcmd.sh"

run_test \
  "5: Strange combo" \
  "hello world informal this is a --test" \
  "hi, this is a --test"

