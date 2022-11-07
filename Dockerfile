FROM debian:bullseye

RUN apt-get update -y \
    && apt-get upgrade -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    neovim \
    curl \
    git \
    tmux \
    sudo \
    locales \
    zsh

ARG USERNAME=slaterade
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME

ENV LANG en_US.UTF-8
ENV LC_ALL C.UTF-8

RUN sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" ||true \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

ADD --chown=$USER_UID:$USER_GID .p10k.zsh /home/$USERNAME/
ADD --chown=$USER_UID:$USER_GID .zshrc /home/$USERNAME/

RUN $HOME/.oh-my-zsh/custom/themes/powerlevel10k/gitstatus/install

CMD ["/usr/bin/zsh"]

