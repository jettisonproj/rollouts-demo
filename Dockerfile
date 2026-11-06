# Build the Go application
FROM golang:1.27.1 as build

WORKDIR /workspace

# Download additional go linter
RUN go install honnef.co/go/tools/cmd/staticcheck@latest

COPY main.go go.mod ./

RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
  CGO_ENABLED=0 go build

# Unit test
FROM build as test-results
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
  FORMAT_RESULT="$(gofmt -d -e -s main.go)" && \
  echo "${FORMAT_RESULT}" && \
  test -z "${FORMAT_RESULT}" && \
  go vet ./... && \
  staticcheck ./... && \
  go fix -diff ./...

# Build the Integration Tests for the Go application
FROM ubuntu:24.04 as integration-test
RUN apt-get update && \
  apt-get -y install curl && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists /var/cache/apt/archives
WORKDIR /root
COPY tests .
CMD [ "./integration-test.sh" ]

# Include only the Go application in the final image
FROM scratch
COPY static/* ./static/
COPY --from=build /workspace/rollouts-demo /rollouts-demo

ENTRYPOINT [ "/rollouts-demo" ]
