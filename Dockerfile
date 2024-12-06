FROM --platform=$BUILDPLATFORM golang:1.22-bookworm AS builder

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY *.go ./

ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN case "${TARGETPLATFORM}" in \
         "linux/amd64")  GOARCH=amd64  ;; \
         "linux/arm64")  GOARCH=arm64  ;; \
    esac \
    && CGO_ENABLED=0 GOOS=linux GOARCH=${GOARCH} go build -o /speedtest

FROM --platform=$TARGETPLATFORM golang:1.22-bookworm
RUN curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash \
    && apt install -y speedtest \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 80

COPY --from=builder /speedtest /speedtest
CMD ["/speedtest"]
