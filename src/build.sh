#!/bin/bash

if [[ -d bin ]]; then
    rm -r bin
fi
mkdir bin

cp src/quig.sh bin/quig

cd ..
tar --exclude=".git*" --exclude="src" -czvf quig.tar.gz quig
cd quig