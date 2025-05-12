#!/bin/zsh

exit_outer_function_if_system_is_not_macos() {
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "MacOS deteted"
  else
    echo "MacOS spesific software (skipping)"
    return 0
  fi
}

ask_to_continue_with_specified_process() {
  if [[ -z "$1" ]]; then
    echo "first parameter can't be empty"
    exit 1
  fi

  local input
  read "input?$1 (Yes/No): "

  if [[ "$input" =~ ^([Yy]([Ee][Ss])?)$ ]]; then
    echo "Proceeding"
    return 0
  elif [[ "$input" =~ ^([Nn]([Oo])?)$ ]]; then
    echo "Skipping"
    return 1
  else
    echo "Incorrect option, please try again"
    ask_to_continue_with_specified_process $1
  fi
}

install_Xcode() {
  exit_outer_function_if_system_is_not_macos
  ask_to_continue_with_specified_process "Do you want to install Xcode?"

  if command -V xcode-select &>/dev/null; then
    echo "Xcode already installed (skipping)"
  else
    echo "Xcode not installed (installing)"
    xcode-select --install
  fi
}

install_Homebrew() {
  ask_to_continue_with_specified_process "Do you want to install Homebrew?"

  if command -V brew &>/dev/null; then
    echo "Homebrew already installed (skipping)"
  else
    echo "Homebrew not installed (installing)"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    brew analytics off
  fi
}

install_Homebrew_packages() {
  ask_to_continue_with_specified_process "Do you want to install Homebrew packages?"
  brew bundle
}

clone_dotfiles_git_repository() {
  ask_to_continue_with_specified_process "Do you want to clone the dotfiles git repository?"

  readonly repository_name="dotfiles"
  readonly repository_dir_original="$HOME/Documents/apps/$repository_name"
  local repository_dir_new=$repository_dir_original

  ask_if_repository_clone_location_is_correct() {
    repository_dir_new=$repository_dir_original
    echo "Where would you like to clone this repository? (Default location): $repository_dir_new"
    local input
    read "input?"
    input="${input#"${input%%[![:space:]]*}"}" #trim leading spaces
    input="${input%"${input##*[![:space:]]}"}" #trim trailing spaces

    if [[ -n "$input" ]]; then
      repository_dir_new="$input/$repository_name"
    fi

    if [[ ! -d "$repository_dir_new" ]]; then
      ask_to_continue_with_specified_process "Is this location correct: $repository_dir_new" || {
        ask_if_repository_clone_location_is_correct
      }
    fi
  }

  ask_if_repository_clone_location_is_correct

  if [[ ! -d "$repository_dir_new" ]]; then
    git clone git@github.com:cj-i/dotfiles.git $repository_dir_new || {
      echo "Git repository failed to clone (exiting)"
      exit 1
    }
    echo "Git repository cloned (success)"
  else
    echo "Git repository already exists (skipping)"
  fi

  cd $repository_dir_new
  unset -f ask_if_repository_clone_location_is_correct
}

stow_dotfiles() {
  ask_to_continue_with_specified_process "Do you want to stow the dotfiles?"

  readonly string="Stowing dotfiles"
  if stow dots; then
    echo "$string (success)"
  else
    echo "$string (failed)"
  fi
}

install_Xcode
install_Homebrew
install_Homebrew_packages
clone_dotfiles_git_repository
stow_dotfiles

echo "Dotfiles setup done"
