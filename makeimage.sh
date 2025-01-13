#!/bin/bash

docker run --privileged --platform linux/amd64 --rm -v $(pwd):/build -it archlinux:latest /build/build.sh
echo "Done!"
