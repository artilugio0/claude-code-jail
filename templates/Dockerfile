# Claude Code container — customize this for your project.
# Add tools your project needs below (e.g. python3, jq, awscli).
FROM ubuntu:24.04

ARG USER_UID=1000
ARG USER_GID=1000

RUN apt-get update && apt-get install -y --no-install-recommends \
    git curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Uncomment to enable Docker support (required for 'ccjail run --allow-docker'):
#RUN install -m 0755 -d /etc/apt/keyrings \
#    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
#    && chmod a+r /etc/apt/keyrings/docker.asc \
#    && tee /etc/apt/sources.list.d/docker.sources <<EOF
#Types: deb
#URIs: https://download.docker.com/linux/ubuntu
#Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
#Components: stable
#Signed-By: /etc/apt/keyrings/docker.asc
#EOF
#RUN apt-get update && apt-get install -y --no-install-recommends docker-ce-cli

RUN userdel --force ubuntu \
    && mkdir /workspace \
    && useradd -u ${USER_UID} -g ${USER_GID} -m -d /home/user user \
    && mkdir -p /home/user/.local/bin \
    && ln -s $(which claude) /home/user/.local/bin/claude \
    && chown -R user /home/user/.local \
    && chown ${USER_UID}:${USER_GID} /workspace

USER user

# Install Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/user/.local/bin:${PATH}"

WORKDIR /workspace

ENTRYPOINT ["claude"]
