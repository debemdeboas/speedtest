FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    curl \
    gnupg

RUN curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
RUN apt install -y speedtest && rm -rf /var/lib/apt/lists/*

EXPOSE 80

WORKDIR /app
COPY speedtest.py /app/

CMD ["python", "speedtest.py"]
