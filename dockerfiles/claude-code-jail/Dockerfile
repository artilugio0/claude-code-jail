FROM ubuntu:24.04

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y curl

RUN useradd user -u 1069 -m -d /home/user
RUN mkdir /development && chown user /development

USER user

RUN sh -c 'curl -fsSL https://claude.ai/install.sh | bash'
ENV PATH=$PATH:/home/user/.local/bin

WORKDIR /development
