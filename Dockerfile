# STEP 1 Build executable binary
ARG BUILD_IMAGE=golang:alpine
FROM ${BUILD_IMAGE} as builder

WORKDIR /workspace

# Install app dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy golang source code from the host
COPY ./ ./

# Get dependancies and Build the binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -installsuffix cgo -o server .

# STEP 2 Build a small image
FROM alpine:3.11.0
RUN apk --no-cache add ca-certificates
WORKDIR /workspace

# Copy our static executable binary
COPY --from=builder /workspace/server .

CMD ["/workspace/server"]