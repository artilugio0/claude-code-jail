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

# Match container user UID/GID to host user to avoid file permission issues.
# The node image ships with a "node" user — we reuse it.
RUN groupmod -g ${USER_GID} node \
    && usermod -u ${USER_UID} -g ${USER_GID} node

USER node
WORKDIR /workspace

ENTRYPOINT ["claude"]
