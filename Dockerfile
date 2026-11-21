# syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM golang:1.27.1 AS go-base
WORKDIR /workspace

# Build the Go application
FROM go-base AS build
COPY go.mod main.go ./
ARG TARGETOS TARGETARCH
RUN --mount=type=cache,target=/go/pkg/mod \
  --mount=type=cache,target=/root/.cache/go-build \
  CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
  go build -trimpath -ldflags="-s -w" -o /out/rollouts-demo

# Unit test / lint (independent of the build stage so BuildKit can run them in parallel)
FROM go-base AS test-results
ARG STATICCHECK_VERSION=2026.2.2
RUN --mount=type=cache,target=/go/pkg/mod \
  --mount=type=cache,target=/root/.cache/go-build \
  go install honnef.co/go/tools/cmd/staticcheck@${STATICCHECK_VERSION}
COPY go.mod main.go ./
RUN --mount=type=cache,target=/go/pkg/mod \
  --mount=type=cache,target=/root/.cache/go-build \
  --mount=type=cache,target=/root/.cache/staticcheck \
  FORMAT_RESULT="$(gofmt -d -e -s main.go)" && \
  echo "${FORMAT_RESULT}" && \
  test -z "${FORMAT_RESULT}" && \
  go vet ./... && \
  staticcheck ./... && \
  go fix -diff ./...

# Build the Integration Tests for the Go application
FROM ubuntu:24.04 AS integration-test
RUN apt-get update && \
  apt-get -y install --no-install-recommends curl && \
  rm -rf /var/lib/apt/lists/*
WORKDIR /root
COPY tests/ .
CMD [ "./integration-test.sh" ]

# Include only the Go application in the final image
FROM scratch
COPY static/ /static/
COPY --from=build /out/rollouts-demo /rollouts-demo
USER 65532:65532

ENTRYPOINT [ "/rollouts-demo" ]
