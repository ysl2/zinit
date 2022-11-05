# syntax=docker/dockerfile:1.3-labs
ARG version=22.04
# shellcheck disable=SC2154
FROM amd64/ubuntu:"${version}"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
  && apt-get install -y --no-install-recommends software-properties-common gnupg-agent \
  && add-apt-repository -y ppa:git-core/ppa \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    bzip2 \
    ca-certificates \
    curl \
    file \
    fonts-dejavu-core \
    g++ \
    gawk \
    git \
    less \
    libz-dev \
    locales \
    make \
    netbase \
    openssh-client \
    patch \
    sudo \
    uuid-runtime \
    tzdata \
    zsh \
  && apt remove --purge -y software-properties-common \
  && apt autoremove --purge -y \
  && rm -rf /var/lib/apt/lists/* \
  && localedef -i en_US -f UTF-8 en_US.UTF-8 \
  && useradd -m -s /usr/bin/zsh zinit \
  && echo 'zinit ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers \
  && su - zinit -c 'mkdir ~/.zinit'

USER zinit
COPY --chown=zinit:zinit . /home/zinit/.zinit/zinit.git
WORKDIR /home/zinit

# RUN python3 <<EOF > /hello
# print("Hello")
# print("World")
# EOF
# RUN bash <<EOF > .zshrc
# #!/usr/bin/env zsh
# builtin source .zinit/zinit.git/zinit.zsh \
# && autoload -Uz _zinit \
# && (( ${+_comps} )) \
# && _comps[zinit]=_zinit
# EOF
COPY <<EOF .zshrc
  \#!/usr/bin/env zsh
  builtin . .zinit/zinit.git/zinit.zsh
  autoload -Uz _zinit
  (( \${+_comps} ))
  _comps[zinit]=_zinit
EOF

ENTRYPOINT ["zsh", "-li"]
