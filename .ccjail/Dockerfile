# Claude Code container — customize this for your project.
# Add tools your project needs below (e.g. python3, jq, awscli).
FROM node:lts-slim

ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code

# Uncomment to enable Docker support (required for 'ccjail run --allow-docker'):
RUN apt-get update && apt-get install -y --no-install-recommends docker.io \
    && rm -rf /var/lib/apt/lists/*

# Match container user UID/GID to host user to avoid file permission issues.
RUN usermod -u ${USER_UID} -g ${USER_GID} node

USER node
WORKDIR /workspace

ENTRYPOINT ["claude"]
