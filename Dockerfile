# Build the Go application
FROM golang:1.24 as build
WORKDIR /go/src/app
COPY main.go go.mod ./
RUN go vet && \
  [ -z "$(go fmt)" ] && \
  CGO_ENABLED=0 go build

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
COPY --from=build /go/src/app/rollouts-demo /rollouts-demo

ENTRYPOINT [ "/rollouts-demo" ]
