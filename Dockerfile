ARG GO_VERSION="1.18"


FROM golang:${GO_VERSION} AS skopeo-build

SHELL [ "/bin/bash", "-euxo", "pipefail", "-c" ]

WORKDIR /usr/src/skopeo

ARG SKOPEO_VERSION="1.12.0"
RUN curl -fsSL "https://github.com/containers/skopeo/archive/v${SKOPEO_VERSION}.tar.gz" \
  | tar -xzf - --strip-components=1

# Bundle default-policy.json into the binary
RUN curl -fsSL https://github.com/felipecrs/skopeo/commit/c37fdf45d00b402b5aa9a1a10e3ac7157d2466a5.diff | git apply

# https://github.com/containers/skopeo/blob/main/install.md#building-a-static-binary
RUN CGO_ENABLED=0 DISABLE_DOCS=1 make BUILDTAGS=containers_image_openpgp GO_DYN_FLAGS=; \
  ./bin/skopeo --version


FROM scratch AS skopeo-bin

COPY --from=skopeo-build /usr/src/skopeo/bin/skopeo /


FROM buildpack-deps:focal-curl AS test

COPY --from=skopeo-bin / /usr/local/bin/

CMD ["skopeo", "copy", "docker://alpine:latest", "docker-archive:alpine.tar"]


# Set skopeo-bin as the default stage
FROM skopeo-bin
