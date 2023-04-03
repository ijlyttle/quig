#!/bin/bash

# clean bin directory
if [[ -d bin ]]; then
    rm -r bin
fi
mkdir bin

cp src/quig.sh bin/quig

exit 0;