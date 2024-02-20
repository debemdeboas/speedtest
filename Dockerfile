FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    curl \
    gnupg

RUN curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash
RUN apt install -y speedtest && rm -rf /var/lib/apt/lists/*

# Accept the license agreements
# RUN bash -c "timeout 5 speedtest < <(echo -e 'YES\nYES')"
RUN timeout 5 speedtest --accept-license --accept-gdpr || exit 0

WORKDIR /app
COPY speedtest.py /app/

CMD ["python", "speedtest.py"]
