FROM golang:1.22-bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
RUN apt install -y speedtest && rm -rf /var/lib/apt/lists/*

EXPOSE 80

WORKDIR /app

COPY go.mod ./
RUN go mod download

COPY *.go ./

RUN CGO_ENABLED=0 GOOS=linux go build -o /speedtest
CMD ["/speedtest"]