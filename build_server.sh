#!/usr/bin/env bash
source ./utils.sh

echo "--- BUILDING RCSSERVER"
RUN "docker build -t rcssserver:latest ./server" -po
echo "--- END BUILDING RCSSERVER"
