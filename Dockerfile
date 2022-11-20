FROM debian:bullseye-slim AS base

# build everything here to prevent bloat in published image
FROM base AS builder

RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git \
    ninja-build \
    gettext \
    libtool \
    libtool-bin \
    autoconf \
    automake \
    cmake \
    g++ \
    pkg-config \
    unzip \
    curl

RUN git clone https://github.com/neovim/neovim \
    && cd neovim \
    && git checkout stable \
    && make CMAKE_BUILD_TYPE=Release \
    && make install

RUN git clone --depth=1 https://github.com/sumneko/lua-language-server \
    && cd lua-language-server \
    && git submodule update --depth 1 --init --recursive \
    && cd 3rd/luamake \
    && ./compile/install.sh \
    && cd ../.. \
    && ./3rd/luamake/luamake rebuild

# back to our regularly scheduled stage
FROM base

RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    && curl -fsSL https://deb.nodesource.com/setup_19.x | bash -

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
    black \
    build-essential \
    fd-find \
    git \
    locales \
    nodejs \
    python3 \
    python3-pip \
    ripgrep \
    sudo \
    tmux \
    unzip \
    zsh

RUN python3 -m pip install -U pip \
    && python3 -m pip install neovim

RUN npm install -g pyright typescript typescript-language-server dockerfile-language-server-nodejs

ARG USERNAME=yossarian
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && chsh -s /usr/bin/zsh $USERNAME

USER $USERNAME

ENV LANG en_US.UTF-8
ENV LC_ALL C.UTF-8

RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" ||true \
    && git clone --depth 1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k \
    && git clone --depth 1 https://github.com/wbthomason/packer.nvim /home/$USERNAME/.local/share/nvim/site/pack/packer/start/packer.nvim \
    && git clone --depth 1 https://github.com/slaterade/neovim-config /home/$USERNAME/.config/nvim

COPY .p10k.zsh /home/$USERNAME/
COPY .zshrc /home/$USERNAME/
COPY .tmux.conf /home/$USERNAME/
COPY --from=builder /usr/local /usr/local
COPY --from=builder /lua-language-server/bin /opt/lua-language-server/bin
COPY --from=builder /lua-language-server/locale /opt/lua-language-server/locale
COPY --from=builder /lua-language-server/meta /opt/lua-language-server/meta
COPY --from=builder /lua-language-server/script /opt/lua-language-server/script
COPY --from=builder /lua-language-server/*.lua /opt/lua-language-server

RUN sudo mkdir -p /opt/lua-language-server/log/cache \
    && sudo chmod 777 /opt/lua-language-server/log/cache

RUN $HOME/.oh-my-zsh/custom/themes/powerlevel10k/gitstatus/install \
    && nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'

CMD ["/usr/bin/zsh", "-c", "cd ~/ && /usr/bin/zsh"]

