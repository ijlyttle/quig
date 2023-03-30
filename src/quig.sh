#!/bin/bash

quarto_directory="/opt/quarto"
regex_version="[0-9]+\.[0-9]+\.[0-9]+"
quarto_shim="/usr/local/bin/quarto"

function quig_resolve()
{
    # check dependencies
    # ref: https://stackoverflow.com/a/33297935
    type curl >/dev/null 2>&1 || { echo >&2 "ERROR: curl required but it's not installed. Aborting."; exit 1; }
    type jq >/dev/null 2>&1 || { echo >&2 "ERROR: jq required but it's not installed. Aborting."; exit 1; }

    # set default
    local default="release"
    if [ -n "$QUARTO_VERSION" ]; then
        local default="$QUARTO_VERSION"
    fi

    # parse argument
    local arg="$default"
    if [ -n "$1" ]; then
        local arg=$1
    fi

    # resolve version
    local version=$arg
    if [ $arg == "release" ]; then
        local version=$(curl -s https://quarto.org/docs/download/_download.json | jq -r .version)
    elif [ $arg == "pre_release" ]; then
        local version=$(curl -s https://quarto.org/docs/download/_prerelease.json | jq -r .version)
    fi

    # validate version
    if [[ ! "$version" =~ ^$regex_version$ ]]; then
        echo >&2 "ERROR: Version must be 'release', 'pre_release' or formatted like '1.2.3'. You provided: '$version'." 
        exit 1
    fi

    # return version
    echo "$version"
    exit 0
}

function quig_tar_url() {

    local version=$1
    local url_path="https://github.com/quarto-dev/quarto-cli/releases/download/v$version"

    # is it Mac?
    if [[ "$OSTYPE" =~ ^darwin ]]; then
        echo "$url_path/quarto-$version-macos.tar.gz"
        exit 0
    fi

    # is it Ubuntu?
    if [[ $(awk -F= '/^NAME/{print $2}' /etc/os-release | sed s/\"//g)="Ubuntu" ]]; then
        local arch=$(dpkg --print-architecture)
        echo "$url_path/quarto-$version-linux-$arch.tar.gz"
        exit 0
    fi
    
    echo >&2 "ERROR: Cannot create URL for download, platform not supported."
    exit 1
}

function quig_extract(){
    if ! local version=$(echo $1 | sed -E "s/^\/opt\/quarto\/($regex_version)\/bin\/quarto$/\1/"); then
        exit 1
    fi

    echo "$version"
    exit 0  
}

function quig_list()
{
    local path_spec="$quarto_directory/*/bin/quarto"
    local path_array=($path_spec)

    # test to see if nothing found
    if [[ "$path_array" == "$path_spec" ]]; then
        echo >&2 "No Quarto versions found at $quarto_directory"
        exit 1
    fi

    local version_array=()
    for path in "${path_array[@]}"
    do
        if local version=$(quig_extract $path); then
            version_array+=($version)
        fi
    done

    echo "${version_array[@]}"
    exit 0
}

function quig_default_get()
{
    if ! [ -f $quarto_shim ]; then
        exit 1
    fi

    local rpath=$(realpath $quarto_shim) 

    if ! local version=$(quig_extract $rpath); then
        exit 1
    fi

    echo "$version"
    exit 0
}

function quig_default_set()
{

    local version="$1"
    local quarto_target="/opt/quarto/$version/bin/quarto"

    # make sure target installation exists
    if [ ! -f "$quarto_target" ]; then 
        echo "Quarto installation not found at $quarto_target"
        exit 1
    fi

    # link shim to target
    ln -sf $quarto_target $quarto_shim

    echo "$version"
    exit 0
}

function quig_default() {

    # if arg provided, set
    if [ -n "$1" ]; then
        if ! version=$(quig_default_set $1); then
            echo $version 
            exit 1
        fi
    fi

    # get default, return    
    local version=$(quig_default_get $1)
    local exit_status=$?
    if [ $exit_status -gt 0 ]; then
        echo >&2 "ERROR: Cannot find quarto installation at $quarto_shim"
        exit 1
    fi  

    echo $version
    exit 0
}

function quig_add()
{

    # resolve version
    local version=$(quig_resolve $1)
    local exit_status=$?
    if [ $exit_status -gt 0 ]; then
        echo >&2 "ERROR: Cannot resolve version."
        exit 1
    fi

    # test if version exists locally
    if [[ -f "$quarto_directory/$version/bin/quarto" ]]; then
        echo >&2 "Quarto version $version already exits at \`/opt/quarto\`."
        exit 1
    fi

    # create directory
    mkdir -p "$quarto_directory/$version"
    local exit_status=$?
    if [ $exit_status -gt 0 ]; then
        echo >&2 "ERROR: Cannot create directory $quarto_directory/$version."
        exit 1
    fi

    # determine download URL
    local url=$(quig_tar_url $version)

    # download to temp file
    local tmpdir=$(mktemp -d)
    echo >&2 "Downloading $url"
    curl -o "${tmpdir}/quarto.tar.gz" -L $url
    exit_status=$?
    if [ $exit_status -gt 0 ]; then
        echo >&2 "ERROR: Cannot download file $url"
        exit 1
    fi

    # unpack into /opt/quarto/
    tar -zxf "${tmpdir}/quarto.tar.gz" -C "/opt/quarto/${version}" --strip-components=1 

    # delete temp file
    rm -r $tmpdir

    echo "$version"
    exit 0
}

function quig_rm()
{

    local version="$1"

    # does directory exist?
    if [[ ! -d "$quarto_directory/$version" ]]; then
        echo >&2 "ERROR: Quarto version $version not found."
        exit 1
    fi

    # don't delete default
    local version_default=$(quig_default)
    if [[ "$version" == "$version_default" ]]; then
        echo >&2 "ERROR: $version is the default version, won't delete."
        exit 1
    fi

    # delete
    rm -r "$quarto_directory/$version"
    echo >&2 "Deleted Quarto version $version"

    echo "$version"
    exit 0
}

function quig_clean()
{

    if ! local version_array=($(quig_list)); then
        echo "No versions found"     
        exit 1
    fi
    
    local version_default=$(quig_default)

    for version in "${version_array[@]}"
    do
        if [[ "$version" != "$version_default" ]]; then
            local result=$(quig_rm $version)
        fi
    done

    exit 0
}

function quig_help()
{
    echo "\n"
    echo "NAME\n"
    echo "\t  quig - manage Quarto installations\n"
    echo "\n"
    echo "DESCRIPTION\n"
    echo "\t  quig manages your Quarto installations on MacOS and Ubuntu\n" 
    echo "\t  (including WSL and containters). Following rig and pyenv,\n"
    echo "\t  you can have multiple Quarto versions installed, and choose\n"
    echo "\t  which one is active.\n"
    echo "\n"
    echo "\t  quig is *very* experimental. Should it prove useful, it is hoped it\n"
    echo "\t  could be built and maintained more robustly, and could support\n"
    echo "\t  more platforms.\n"
    echo "\n"
    echo "\t  The API for quig tries to follow the API for rig.\n"
    echo "\n"
    echo "\t  The implementation is straightforward:\n"
    echo "\t  - each Quarto version has its own directory: \`/opt/quarto/<version>\`.\n"
    echo "\t  - manages symlink from \`/usr/local/bin/quarto\` to \`/opt/quarto/<version>\`.\n"
    echo "\n"
    echo "USAGE:\n"
    echo "\t  quig [SUBCOMMAND]\n"
    echo "\n"
    echo "SUBCOMMANDS:\n"
    echo "\t  add\n"
    echo "\t  clean\n"
    echo "\t  default\n"
    echo "\t  help\n"
    echo "\t  list\n"
    echo "\t  resolve\n"
    echo "\t  rm\n"
    echo "\t  upgrade\n"
    echo "\n"
    echo "EXAMPLES:\n"
    echo "\t  # Add latest pre-release snapshot\n"
    echo "\t  sudo quig add pre_release\n"
    echo "\n"
    echo "\t  # Add version based \$QUARTO_VERSION or use \"release\"\n"
    echo "\t  sudo quig add\n"
    echo "\n"
    echo "\t  # Add specific version\n"
    echo "\t  sudo quig add 1.3.290\n"
    echo "\n"
    echo "\t  # List installed versions\n"
    echo "\t  quig list\n"
    echo "\n"
    echo "\t  # Set default version\n"
    echo "\t  sudo quig default 1.3.290\n"
    echo "\n"
    echo "\t  # Add pre_release version, set as default, remove all other versions\n"
    echo "\t  sudo quig upgrade pre_release\n"
    echo "\n"
    echo "\t  # Remove all versions except default\n"
    echo "\t  sudo quig clean\n"    
}

if [[ "$1" == "resolve" ]]; then

    version=$(quig_resolve $2)
    exit_status=$?
    if [ $exit_status -gt 0 ]; then
        echo >&2 "ERROR: Cannot resolve version."
        exit 1
    fi

    echo "$version"
    exit 0    
fi

if [[ "$1" == "add" ]]; then

    # elevate permissions, if needed
    if [ "$EUID" != 0 ]; then
        echo "Requires sudo privilges."
        sudo "$0" "$@"
        exit $?
    fi

    version=$(quig_add $2)
    exit_status=$?    
    if [ $exit_status -gt 0 ]; then
        echo >&2 "Quarto version $2 not installed."
        exit 1
    fi
    echo "Added Quarto $version to \`$quarto_directory\`"    

    # if no default, set default
    version_default=$(quig_default_get)
    exit_status=$?    
    if [ $exit_status -gt 0 ]; then
        # need to set default
        version_default=$(quig_default $version)
        echo "Set Quarto $version as default."    
    fi    

    exit 0    
fi

if [[ "$1" == "default" ]]; then

    # elevate permissions, if needed
    if [ "$EUID" != 0 ]; then
        echo "Requires sudo privilges."
        sudo "$0" "$@"
        exit $?
    fi

    version=$(quig_default $2)
    exit_status=$?    
    if [ $exit_status -gt 0 ]; then
        echo >&2 "ERROR: Cannot set default Quarto version."
        exit 1
    fi

    echo "Default quarto version is $version"    
    exit 0   
fi

if [[ "$1" == "list" ]]; then

    # use outer set of parens to parse array
    if ! version_array=($(quig_list)); then
        exit 1
    fi
    
    version_default=$(quig_default)

    for version in "${version_array[@]}"
    do
        default=""
        if [[ "$version" == "$version_default" ]]; then
            default="(default)"
        fi
        echo $version $default
    done
    exit 0   
fi

if [[ "$1" == "rm" ]]; then

    # elevate permissions, if needed
    if [ "$EUID" != 0 ]; then
        echo "Requires sudo privilges."
        sudo "$0" "$@"
        exit $?
    fi

    version=$(quig_rm $2)
    exit_status=$?    
    if [ $exit_status -gt 0 ]; then
        exit 1
    fi

    exit 0
fi

if [[ "$1" == "clean" ]]; then

    # elevate permissions, if needed
    if [ "$EUID" != 0 ]; then
        echo "Requires sudo privilges."
        sudo "$0" "$@"
        exit $?
    fi

    version=$(quig_clean)
    exit_status=$?    
    if [ $exit_status -gt 0 ]; then
        exit 1
    fi

    exit 0
fi

if [[ "$1" == "upgrade" ]]; then

    # elevate permissions, if needed
    if [ "$EUID" != 0 ]; then
        echo "Requires sudo privilges."
        sudo "$0" "$@"
        exit $?
    fi

    # add
    version=$(quig_add $2)
    exit_status=$?    
    if [ $exit_status -gt 0 ]; then
        echo >&2 "Quarto version $2 not installed."
        exit 1
    fi

    # set default
    version=$(quig_default $version)
    exit_status=$?    
    if [ $exit_status -gt 0 ]; then
        echo >&2 "ERROR: Cannot set default Quarto version."
        exit 1
    fi

    echo "Default quarto version is $version"    

    # clean
    version=$(quig_clean)
    exit_status=$?    
    if [ $exit_status -gt 0 ]; then
        exit 1
    fi

    exit 0
fi

if [[ "$1" == "help" || -z $1 ]]; then
    echo -e $(quig_help)
    exit 0
fi

# no options recignized
echo >&2 "ERROR: option \`${1}\` not recognized; use \`quig help\` to see options."
exit 1