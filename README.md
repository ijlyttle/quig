# quig

The purpose of **quig** is to help you manage installation of [Quarto](https://quarto.org/) versions on MacOS or (Ubuntu) Linux.
If you use Windows, you could use this with WSL or an Ubuntu container.

This is aimed at folks who want to stay current with the "bleeding-edge" of Quarto, and thus may find it handy to work with multiple versions, switching between them.

It is inspired by [pyenv](https://github.com/pyenv/pyenv) and [rig](https://github.com/r-lib/rig); my deepest apologies to rig's author, Gábor Csárdi, for appropriating the name for this pale imitation. In the event that Posit wishes to create and support a similar (presumably much better) tool, I would happily step aside and support such an effort. 

## Strategy

This follows the strategy outlined in [Posit's "Quarto Install" document](https://docs.posit.co/resources/install-quarto/#quarto-tar-file-install):

- maintain a collection of Quarto versions at `/opt/quarto/`.

- download a `tar.gz` file according to the version, platform (MacOS or Linux), and Linux architecture (`amd64` or `arm64`).

- unpack it into `/opt/quarto/<version>/`.

- add a symbolic link from `/usr/local/bin/quarto` to a `default` version in the collection.

## Usage

Certain of these commands will require root privileges; you will be prompted if needed.

Use `quig add` to add a version to your collection:

  - `release` and `pre_release` are resolved to current Quarto release and pre-release versions.
  - defaults first to environment variable named `QUARTO_VERSION` then to `release`
  - you can use `quarto resolve` to preview what version you would get.

Examples:

```bash 
quig add 1.3.290
```

```bash
quig add
```

```bash
(QUARTO_VERSION=pre_release quig add)
```

```bash
quig add pre_release
```

You can use the `list`, `default` and `rm` subcommands to maintain your collection:

```bash
quig list
```

```bash
quig default 1.3.147
```

```bash
quig rm 1.3.147
``` 

The API is designed to follow (a subset of) rig's API. That said, there are a couple of extensions.

Quarto installations each take ~330 MB of disk space. 
You may occasionally want to cut back.
Use the `clean` subcommand to remove all but the `default` version.

```bash
quig clean
```

The `upgrade` subcommand will `add`, set the `default`, then `clean`. 
Let's say you've set `QUARTO_VERSION="pre_release"`; this will keep you up-to-date with `pre_release` and keep only the newest version:

```bash
quig upgrade
```

## Installation

???

