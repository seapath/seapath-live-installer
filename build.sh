#!/bin/bash -e

make build

if [ -f live-image-amd64.hybrid.iso ]; then
    exit 0
else
    echo "Build failed, see output log"
    exit 1
fi
