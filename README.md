# Argo Rollouts Demo Application

This forks the upstream [Argo Rollouts Demo](https://github.com/argoproj/rollouts-demo) and adds a CI/CD demo.

# Local Development

## Running the Server

```
go run main.go
```

See the output for the port which can be accessed through a browser

## Formatting the Code

```
go fmt
```

## Linting the Code

```
go vet
```

## Running the Integration Test

```
./tests/integration-test.sh http://localhost:8080
```

# Docker Development

## Building the Image

```
docker build -t osoriano/rollouts-demo .
```

## Running the Image

```
docker run --rm -it -p 8080:8080 osoriano/rollouts-demo
```

## Building the Integration Test

```
docker build -t osoriano/rollouts-demo-integration-test --target integration-test .
```

## Running the Integration Test

```
docker run --rm -it --net host osoriano/rollouts-demo-integration-test ./integration-test.sh http://localhost:8080
```
