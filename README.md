# skopeo-bin

This project aims to provide static binaries for [skopeo](https://github.com/containers/skopeo), in which you can install on any system without the need of any package manager. It is especially useful for distributions that do not have skopeo in their repositories, like Ubuntu 20.04 and olders.

Note that using skopeo as a static binary is not recommended by the maintainers of skopeo ([more information here](https://github.com/containers/skopeo/blob/main/install.md#building-a-static-binary)), especially for security reasons, therefore use it at your own risk.

## Roadmap

- [x] Provide static binaries for linux/amd64 as GitHub Releases
- [x] Bundle a default `policy.json` file to make skopeo work out of the box
- [x] Provide a scratch-based docker image with the static binaries for linux/amd64
- [ ] Automate the build and release process with GitHub Actions
- [ ] Provide static binaries for more architectures
- [ ] Check daily for new versions of skopeo and release new binaries automatically

## Differences from the official skopeo

There is only one difference between the official skopeo and this project: this one has a default `policy.json` embedded which is mandatory for skopeo to work. The official skopeo does not bundle this file, and it is up to the user to provide one (usually provided by the distribution's package manager).

- <https://github.com/containers/skopeo/pull/2014>

## Install

There are two methods to install `skopeo-bin`:

### From GitHub Releases

You can download the static binary from the [GitHub Releases](https://github.com/felipecrs/skopeo-bin/releases) and place it under a directory in your `$PATH` variable, like `/usr/local/bin/skopeo`:

```bash
# pick any version you want from the releases page
version="1.13.1"

# download the static binary
sudo curl -L --output /usr/local/bin/skopeo https://github.com/felipecrs/skopeo-bin/releases/download/v${version}/skopeo.linux-amd64

# make it executable
sudo chmod +x /usr/local/bin/skopeo
```

### From the docker image

If you want to bundle skopeo in a docker image, you have an [easier way](https://ghcr.io/felipecrs/skopeo-bin) to install it:

```Dockerfile
FROM ubuntu:20.04

COPY --from=ghcr.io/felipecrs/skopeo-bin:1.13.1 / /usr/local/bin/
```

## Building skopeo-bin

It should be as simple as:

```bash
# Build and output the static binary to the current directory
docker build https://github.com/felipecrs/skopeo-bin.git --output .

# Check if it works
./skopeo --version
```

## Releasing

As the release process is not automated yet, you can run the following command to release a new version:

```console
scripts/build_and_release.sh 1.13.1
```
