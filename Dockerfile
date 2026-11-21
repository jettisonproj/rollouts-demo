# Build the Go application
FROM golang:1.27.1 AS build

WORKDIR /workspace

# Copy the go source
COPY go.mod go.sum main.go ./

# Build Main Executable
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
  CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o rollouts-demo main.go

# Unit test
FROM build AS test-results
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
  FORMAT_RESULT="$(gofmt -d -e -s main.go)" && \
  echo "${FORMAT_RESULT}" && \
  test -z "${FORMAT_RESULT}" && \
  go vet ./... && \
  go tool staticcheck ./... && \
  go fix -diff ./...

# Build the Integration Tests for the Go application
FROM ubuntu:24.04 AS integration-test
RUN apt-get update && \
  apt-get -y install curl && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists /var/cache/apt/archives
WORKDIR /root
COPY tests/ .
CMD [ "./integration-test.sh" ]

# Include only the Go application in the final image
FROM scratch
COPY static/ /static/
COPY --from=build /workspace/rollouts-demo /rollouts-demo

ENTRYPOINT [ "/rollouts-demo" ]
