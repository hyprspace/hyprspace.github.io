#!/bin/bash

set -e

# Unset this from the environment.
unset HAVE_SUDO_ACCESS

# Check for the latest tagged release version from the GitHub repository.
get_latest_release() {
  curl -s https://api.github.com/repos/hyprspace/hyprspace/releases/latest \
   | grep tag_name \
   | sed -E 's/.*"([^"]+)".*/\1/'
}

# Nicely abort the install if something goes wrong and print out what
# went wrong. Created from the brew.sh installation script.
# Thank you to Homebrew developers for the amazing work!
abort() {
    printf "%s\n" "$@"
    exit 1
}

# Created from the brew.sh installation script.
shell_join() {
    local arg
    printf "%s" "$1"
    shift
    for arg in "$@"; do
	printf " "
	printf "%s" "${arg// /\ }"
    done
}

# Determine if we have sudo access heavily inspired by the Homebrew
# installation script. Checkout brew.sh if you're on a Mac and haven't yet.
have_sudo_access() {
    if [[ ! -x "/usr/bin/sudo" ]]; then
	return 1
    fi

    local -a SUDO=("/usr/bin/sudo")

    local -a SUDO=("/usr/bin/sudo")

    if [[ -n "${SUDO_ASKPASS-}" ]]; then
	SUDO+=("-A")
	
    elif [[ -n "${NONINTERACTIVE-}" ]]; then
	SUDO+=("-n")
    fi

    if [[ -z "${HAVE_SUDO_ACCESS-}" ]]; then
	if [[ -n "${NONINTERACTIVE-}" ]]; then
	    "${SUDO[@]}" -l mkdir &>/dev/null
	else
	    "${SUDO[@]}" -v && "${SUDO[@]}" -l mkdir &>/dev/null
	fi
	HAVE_SUDO_ACCESS="$?"
    fi

    if [[ "$os" == "darwin" ]] && [[ "${HAVE_SUDO_ACCESS}" -ne 0 ]]; then
	abort "Need sudo access on macOS (e.g. the user ${USER} needs to be an Administrator)!"
    fi

  return "${HAVE_SUDO_ACCESS}"
}

# Execute the parameter array as a cmd on the host.
# Created from the brew.sh installation script.
execute() {
    if ! "$@"; then
	abort "$(printf "Failed during: %s" "$(shell_join "$@")")"
    fi
}

# Execute the parameter array as a sudo cmd.
# Created from the brew.sh installation script.
execute_sudo() {
    local -a args=("$@")
    if have_sudo_access; then
	if [[ -n "${SUDO_ASKPASS-}" ]]; then
	    args=("-A" "${args[@]}")
	fi

	echo "/usr/bin/sudo" "${args[@]}"
	execute "/usr/bin/sudo" "${args[@]}"
    else
	echo "${args[@]}"
	execute "${args[@]}"
    fi
}

# Use uname to determine the computer's ARCH and OS.
os=$( echo "$(uname -s)" | tr -s  '[:upper:]'  '[:lower:]' )
arch=$( echo "$(uname -m)" | tr -s  '[:upper:]'  '[:lower:]' )

# Get the latest tagged release from GitHub.
latest=$(get_latest_release)

echo "Downloading Hyprspace..."

if [ "$arch" == "x86_64" ]; then
        arch="amd64"
fi

if [[ "$os" == "darwin" ]]; then
    if [[ "$arch" == "arm64" ]]; then
	install_dir=/opt/hyprspace
    else
	install_dir=/usr/local
    fi
else
    install_dir=/usr
fi


curl --fail --location --progress-bar --output hyprspace https://github.com/hyprspace/hyprspace/releases/download/$latest/hyprspace-$latest-$os-$arch
chmod a+x hyprspace

echo "Install requires root permissions to write to $install_dir/bin/hyprspace"
execute_sudo mkdir -p $install_dir/bin
execute_sudo mv hyprspace $install_dir/bin/hyprspace


echo ""
echo "Hyprspace was installed successfully to $install_dir/bin/hyprspace"
if command -v hyprspace >/dev/null; then
    echo "Run 'hyprspace --help' to get started"
else
    case $SHELL in
    /bin/zsh) shell_profile=".zshrc" ;;
    *) shell_profile=".bashrc" ;;
    esac
    echo "Run the following two commands in your terminal to add Hyprspace to your ${tty_bold}PATH${tty_reset}:"
    echo
    echo "  echo 'export PATH=\"$install_dir/bin:\$PATH\"' >> $shell_profile"
    echo "  export PATH=\"$install_dir/bin:\$PATH\""
    echo
    echo "Run '$install_dir/bin/hyprspace --help' to get started"
fi
