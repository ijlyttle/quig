#!/bin/bash

# argument is directory in which to create the tarball,
# if none then create in parent directory

path="$1"
if [[ -z "$path" || ! -d $(realpath "$path") ]]; then
    path=".."
    echo >&2 using parent-directory
fi
directory=$(realpath "$path")

filepath="$directory/quig.tar.gz"

cd ..
tar --exclude=".git*" --exclude="src" -czvf $filepath quig >&2
cd quig

echo $filepath