#!/bin/bash

set -euxo pipefail

latest_tag=$(basename "$(curl -fsSL -o /dev/null -w "%{url_effective}" https://github.com/containers/skopeo/releases/latest)")

if [[ "${1:-"latest"}" == "latest" ]]; then
    readonly version="${latest_tag#v}"
else
    readonly version="${1}"
fi

readonly git_tag="v${version}"

# Find go version
if [[ "${version}" == "1.15."* ]]; then
    # https://github.com/containers/skopeo/pull/2252
    go_version="1.20"
else
    go_version=$(
        curl -fsSL "https://github.com/containers/skopeo/raw/${git_tag}/go.mod" |
            grep --extended-regexp --only-matching '^go [0-9]+\.[0-9]+' |
            awk '{print $2}'
    )
fi

echo "Building skopeo ${version} with go ${go_version}"

rm -rf ./binaries

docker run --privileged --rm --pull=always tonistiigi/binfmt --install arm64

export BUILDX_BUILDER="skopeo-bin"

docker buildx create --name "${BUILDX_BUILDER}"
trap 'docker buildx rm --force "${BUILDX_BUILDER}"' EXIT

for platform in "linux/amd64" "linux/arm64"; do
    docker buildx build . \
        --pull \
        --platform "${platform}" \
        --build-arg "SKOPEO_VERSION=${version}" \
        --build-arg "GO_VERSION=${go_version}" \
        --target bin-tagged \
        --output ./binaries
done

# Delete the release if it already exists
if gh release view "${git_tag}" &>/dev/null; then
    gh release delete "${git_tag}" --cleanup-tag --yes 2>&1
fi

# Check if the release is the latest
if [[ "${latest_tag}" == "${git_tag}" ]]; then
    latest=true
    extra_args=(--tag ghcr.io/felipecrs/skopeo-bin:latest)
else
    extra_args=()
    latest=false
fi

gh release create "${git_tag}" --title "${git_tag}" --target master --latest="${latest}" \
    --notes "The original release notes can be found [here](https://github.com/containers/skopeo/releases/tag/${git_tag})." \
    binaries/*

docker build . \
    --platform linux/amd64,linux/arm64 \
    --build-arg "SKOPEO_VERSION=${version}" \
    --build-arg "GO_VERSION=${go_version}" \
    --tag "ghcr.io/felipecrs/skopeo-bin:${version}" \
    "${extra_args[@]}" \
    --push
