FROM debian:bookworm-slim

# Install deps
RUN apt-get update && apt-get install -y curl wget jq tar git docker.io

# Install depot
RUN curl -fsSL https://depot.dev/install-cli.sh -o /tmp/install-cli.sh && \
    sh /tmp/install-cli.sh 2.100.12 && \
    rm /tmp/install-cli.sh

# Add depot to PATH
ENV PATH="/root/.depot/bin:$PATH"

# Ensure depot is installed and working
RUN depot --version

# Download test runner CLI
COPY download_test_runner.sh /tmp/download_test_runner.sh
RUN --mount=type=secret,id=test_runner_downloader_token,env=GITHUB_TOKEN /tmp/download_test_runner.sh