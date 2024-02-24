#!/bin/bash

echo "env: dev"
cp ./src/env/env_local.mo ./src/env/env.mo

# UI
dfx deploy ui

