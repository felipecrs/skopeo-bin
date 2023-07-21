ARG SKOPEO_VERSION="1.13.1"
# The go version should match the go version in skopeo's go.mod
ARG GO_VERSION="1.18"


# Build skopeo from source
FROM golang:${GO_VERSION} AS build

SHELL [ "/bin/bash", "-euxo", "pipefail", "-c" ]

WORKDIR /workspace

ARG SKOPEO_VERSION
RUN curl -fsSL "https://github.com/containers/skopeo/archive/v${SKOPEO_VERSION}.tar.gz" \
  | tar -xzf - --strip-components=1

# Bundle default-policy.json into the binary to provide a working out-of-the-box experience
# https://github.com/containers/skopeo/pull/2014
RUN curl -fsSL https://github.com/containers/skopeo/pull/2014.diff | git apply

# https://github.com/containers/skopeo/blob/main/install.md#building-a-static-binary
RUN CGO_ENABLED=0 DISABLE_DOCS=1 make BUILDTAGS=containers_image_openpgp GO_DYN_FLAGS=; \
  # Check if the binary is working \
  ./bin/skopeo --version


# This stage renames the binary to include the version and the GOOS/GOARCH
FROM build AS build-tagged

ARG SKOPEO_VERSION
RUN tagged_binary="$(eval "$(go tool dist env)" && echo "skopeo.${GOOS}-${GOARCH}")"; \
  mv -f ./bin/skopeo "./bin/${tagged_binary}"


# Adds only the binary to the scratch image
FROM scratch AS bin

COPY --from=build /workspace/bin/skopeo /


# Adds only the tagged binary to the scratch image
FROM scratch AS bin-tagged

COPY --from=build-tagged /workspace/bin/skopeo.* /


# A testing stage that checks if the binary is working
FROM buildpack-deps:focal-curl AS test

COPY --from=bin / /usr/local/bin/

RUN skopeo copy docker://hello-world docker-archive:hello-world.tar; \
  rm -f hello-world.tar


# Set the scratch bin as the default stage
FROM bin
