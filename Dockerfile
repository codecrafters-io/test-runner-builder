FROM debian:bookworm-slim

# Install deps
RUN apt-get update && apt-get install -y curl

# Install depot
RUN curl -fsSL https://depot.dev/install-cli.sh -o /tmp/install-cli.sh && \
    sh /tmp/install-cli.sh 2.100.12 && \
    rm /tmp/install-cli.sh

# Add depot to PATH
ENV PATH="/root/.depot/bin:$PATH"

# Ensure depot is installed and working
RUN depot --version