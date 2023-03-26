# quig

The purpose of **quig** is to help you manage installation of [Quarto](https://quarto.org/) versions on MacOS or (Ubuntu) Linux.

It is inspired by [pyenv](https://github.com/pyenv/pyenv) and [rig](https://github.com/r-lib/rig); my deepest apologies to rig's author, Gábor Csárdi, for appropriating the name for this pale imitation.

## Usage

(not yet working, this is aspirational)

```bash
quig resolve pre_release
```

```bash
sudo quig add
```

```bash
(QUARTO_VERSION=pre_release sudo quig add)
```

```bash
sudo quig add pre_release
```

```bash
quig list
```

```bash
sudo quig default 1.3.147
```

```bash
sudo quig rm 1.3.147
``` 

## Installation

???

## Strategy

This follows the strategy outlined in [Posit's "Quarto Install" document](https://docs.posit.co/resources/install-quarto/#quarto-tar-file-install):

- download a `tar.gz` file according to the version, platform (MacOS or Linux), and Linux architecture (`amd64` or `arm64`).

- unpack it into `/opt/quarto/<version>/` (delete tarball).

- add a symbolic link to `/usr/local/bin/quarto`.