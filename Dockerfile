# syntax=docker/dockerfile-upstream:master

FROM ubuntu:latest

LABEL org.label-schema.name="vladdoster/dotfiles"
LABEL org.opencontainers.image.title="dotfiles"
LABEL org.opencontainers.image.source="http://dotfiles.vdoster.com/"
LABEL org.opencontainers.image.description="Containerized dotfiles environment"

ARG USER

ENV USER ${USER:-dotfiles}
ENV HOME /home/${USER}
ENV TERM xterm

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update --quiet=2 \
 && apt-get install --assume-yes --no-install-recommends --quiet=2 \
  autoconf automake \
  build-essential bzip2 \
  cmake curl \
  file \
  g++ gawk gcc gettext git gosu \
  jq \
  less libtool libtool-bin libz-dev locales \
  make man-db \
  ncurses-base ncurses-bin ncurses-dev ncurses-term npm \
  patch pkg-config python3 python3-dev python3-pip python3-setuptools python3-bdist-nsi perl \
  readline-common ruby ruby-dev \
  subversion sudo software-properties-common \
  tar texinfo tree \
  unzip \
  wget \
  xz-utils \
  zsh

# RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
#     echo 'LANG="en_US.UTF-8"'>/etc/default/locale && \
#     dpkg-reconfigure --frontend=noninteractive locales && \
#     update-locale LANG=en_US.UTF-8

# Setup non-root user
RUN useradd \
  --create-home \
  --gid root --groups sudo \
  --home-dir ${HOME} \
  --shell "$(which zsh)" \
  --uid 1001 \
  ${USER} \
 && echo "${USER} ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers \
 && passwd --delete ${USER} \
 && chown --recursive ${USER} ${HOME}

COPY --chown=${USER}:1001 . ${HOME}/.local/share/zinit/zinit.git
COPY --chown=${USER}:1001 ./scripts/zshrc ${HOME}/.zshrc

USER ${USER}
WORKDIR ${HOME}/.local/share/zinit/zinit.git


RUN ZINIT_HOME_DIR="${HOME}/.local/share/zinit" zsh --interactive -c "@zinit-scheduler burst"

ENTRYPOINT ["zsh"]
CMD ["--login", "--interactive", "--no-globalrcs"]

# vim:syn=dockerfile:ft=dockerfile:fo=croql:sw=2:sts=2
