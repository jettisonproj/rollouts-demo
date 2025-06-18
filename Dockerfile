FROM golang:1.24 as build
WORKDIR /go/src/app
COPY main.go go.mod .
RUN go vet && \
  [ -z "$(go fmt)" ] && \
  CGO_ENABLED=0 go build

FROM scratch
COPY static/* ./
COPY --from=build /go/src/app/rollouts-demo /rollouts-demo

ENTRYPOINT [ "/rollouts-demo" ]
