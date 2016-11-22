#!/usr/bin/env bash

# Directory of this script
CONFIG_ROOT=$(cd `dirname $0` && pwd)

# Store location of config root
echo "CONFIG_ROOT='${CONFIG_ROOT}'" > ${HOME}/.config_root

function _link() {
  if $OS_OSX ; then
    ln -sfh $1 $2
  else
    ln -sf $1 $2
  fi
  echo "Linked $1 -> $2"
}

# Link
_link ${CONFIG_ROOT}/profile/.bash_profile ${HOME}/.bash_profile
_link ${CONFIG_ROOT}/tmux/.tmux.conf ${HOME}/.tmux.conf
_link ${CONFIG_ROOT}/vim/.vimrc ${HOME}/.vimrc
_link ${CONFIG_ROOT}/git/.gitconfig ${HOME}/.gitconfig
_link ${CONFIG_ROOT}/vim/.vim ${HOME}/.vim
