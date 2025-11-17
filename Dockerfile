FROM debian:bookworm-slim

# Install deps
RUN apt-get update && apt-get install -y curl wget jq tar git docker.io

# Install Go
RUN wget https://go.dev/dl/go1.25.0.linux-amd64.tar.gz -O /tmp/go.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz

ENV PATH="/usr/local/go/bin:$PATH"

# Ensure Go is installed and working
RUN go version

# Install depot
RUN curl -fsSL https://depot.dev/install-cli.sh -o /tmp/install-cli.sh && \
    sh /tmp/install-cli.sh 2.100.12 && \
    rm /tmp/install-cli.sh

# Add depot to PATH
ENV PATH="/root/.depot/bin:$PATH"

# Ensure depot is installed and working
RUN depot --version

COPY builder/ /tmp/builder/
RUN cd /tmp/builder && go build -o /var/opt/test-runner-builder main.go

# Ensure the Go program is installed and working
RUN /var/opt/test-runner-builder --version

# Download test runner to a directory (mounted during docker builds)
COPY download_test_runner.sh /tmp/download_test_runner.sh
RUN --mount=type=secret,id=test_runner_downloader_token,env=GITHUB_TOKEN /tmp/download_test_runner.sh

# Ensure the test runner is installed and working
RUN /var/opt/test-runner/test-runner --version