# syntax=docker/dockerfile:1
ARG GO_IMAGE=golang:1.26.9-bookworm
FROM --platform=$BUILDPLATFORM ${GO_IMAGE} AS dependencies
WORKDIR /src
ENV CGO_ENABLED=0 GOTOOLCHAIN=local
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download && go mod verify

FROM dependencies AS build
COPY . .
# Run checks on the builder's native platform before cross-compiling.
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go test -mod=readonly ./...
ARG TARGETOS
ARG TARGETARCH
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    mkdir -p /out && \
    suffix="" && if [ "$TARGETOS" = windows ]; then suffix=".exe"; fi && \
    GOOS=$TARGETOS GOARCH=$TARGETARCH go build -mod=readonly -trimpath -buildvcs=false -o /out/tweego${suffix} .

FROM scratch AS artifact
COPY --from=build /out/ /
COPY LICENSE /LICENSE
