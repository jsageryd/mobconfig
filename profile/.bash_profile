# Load profile recursively

# Set config root
source ${HOME}/.config_root

# Recursive source
function source_recursively() {
  [ -d "${1}" ] || return 1
  includes=$(find "${1}" -iname '*.inc' | sort)
  while read inc ; do
    [ -f "${inc}" ] && source "${inc}"
  done <<< "${includes}"
}

source_recursively "${CONFIG_ROOT}/profile"
