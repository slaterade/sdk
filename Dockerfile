FROM debian:bullseye

RUN apt-get -y update \
    && apt-get -y upgrade \
    && apt-get install -y \
    build-essential \
    neovim \
    zsh \
    curl \
    git \
    && sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

ENTRYPOINT ["/usr/bin/zsh"]
