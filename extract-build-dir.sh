#!/bin/sh
echo "$(tput bold)Creating build folder $(tput sgr0)..."
docker build --target build -o- . | tar xf - --strip-components=3 home/gradle/faust-gen/build
