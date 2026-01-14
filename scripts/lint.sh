#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR/api-gateway" && npm run lint && cd -
cd "$ROOT_DIR/microservices/comments-svc" && npm run lint && cd -
cd "$ROOT_DIR/microservices/organizations-svc" && npm run lint && cd -
cd "$ROOT_DIR/microservices/users-svc" && npm run lint && cd -
