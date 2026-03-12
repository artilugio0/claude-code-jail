#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

docker build -t claude-code-jail "${SCRIPT_DIR}/../dockerfiles/claude-code-jail/"
