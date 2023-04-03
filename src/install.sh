#!/bin/bash

# elevate permissions, if needed
if [ "$EUID" != 0 ]; then
    echo "Requires sudo privilges."
    sudo "$0" "$@"
    exit $?
fi

# returns full path of the src directory
src_dir="$(realpath $(dirname "$0"))"

tardir=$(realpath $1)
if [[ -z "$tardir" || ! -f "$tardir" ]]; then
    echo using temp directory
    tardir=$(mktemp -d)
fi

$src_dir/build.sh
filepath=$($src_dir/make-tarball.sh $tardir)

tar xzf "$filepath" -C /opt
ln -sf /opt/quig/bin/quig /usr/local/bin/quig

echo $(quig --version)
exit 0