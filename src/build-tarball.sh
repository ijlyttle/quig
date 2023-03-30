#!/bin/bash

# clean bin directory
if [[ -d bin ]]; then
    rm -r bin
fi
mkdir bin

cp src/quig.sh bin/quig

filename="quig.tar.gz"

cd ..
tar --exclude=".git*" --exclude="src" -czvf $filename quig >&2
filepath=$(realpath $filename)
cd quig

echo $filepath
exit 0;