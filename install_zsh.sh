#!/bin/bash
set -e

# Проверяем, что это Arch Linux
if [ ! -f /etc/arch-release ]; then
    echo "Скрипт работает только на Arch Linux. Выходим."
    exit 1
fi

echo "Обновляем систему и устанавливаем необходимые пакеты..."
sudo pacman -Syu --noconfirm zsh git zoxide eza neovim fzf curl fd bat lazygit

# Определяем пути для oh-my-zsh и кастомных файлов
export ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Устанавливаем oh-my-zsh, если не установлен
if [ ! -d "$ZSH" ]; then
    echo "Устанавливаем oh-my-zsh..."
    git clone https://github.com/ohmyzsh/ohmyzsh.git "$ZSH"
fi

# Устанавливаем тему Powerlevel10k, если её ещё нет
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    echo "Устанавливаем тему Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# Функция для установки плагинов
install_plugin() {
    local repo_url=$1
    local dest_dir=$2
    if [ ! -d "$dest_dir" ]; then
        echo "Устанавливаем плагин из $repo_url..."
        git clone --depth=1 "$repo_url" "$dest_dir"
    fi
}

# Устанавливаем плагины для zsh
install_plugin https://github.com/zsh-users/zsh-autosuggestions          "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
install_plugin https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
install_plugin https://github.com/zsh-users/zsh-syntax-highlighting.git  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
install_plugin https://github.com/zsh-users/zsh-completions              "$ZSH_CUSTOM/plugins/zsh-completions"
install_plugin https://github.com/matthiasha/zsh-uv-env                  "$ZSH_CUSTOM/plugins/zsh-uv-env"

# Устанавливаем UV по официальной инструкции
if ! command -v uv >/dev/null 2>&1; then
    echo "UV не найден – устанавливаем..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    echo "UV уже установлен – обновляем..."
fi
uv self update || echo "Обновление UV не удалось, возможно uv не установлен корректно."

# Устанавливаем NVM, если не установлен
if [ ! -d "$HOME/.nvm" ]; then
    echo "Устанавливаем NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    # Подгружаем nvm (может потребоваться новый запуск шелла)
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Бэкап старого .zshrc, если он есть
if [ -f "$HOME/.zshrc" ]; then
    echo "Сохраняем текущий .zshrc в .zshrc.backup"
    cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
fi

echo "Записываем новый конфиг в ~/.zshrc..."
cat > "$HOME/.zshrc" << 'EOF'
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Игнорировать команды, начинающиеся с пробела
setopt HIST_IGNORE_SPACE

# Немедленно добавлять команды в историю
setopt INC_APPEND_HISTORY

# Разделять историю между всеми сессиями
setopt SHARE_HISTORY

# Игнорировать последовательные дубликаты команд
setopt HIST_IGNORE_DUPS

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
zstyle ':omz:update' frequency 14

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="yyyy-mm-dd"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-syntax-highlighting
  zsh-completions
  fzf
  uv
  zsh-uv-env
  rust
  golang
)

source $ZSH/oh-my-zsh.sh

# Инициализация zoxide (должно быть после Oh My Zsh)
eval "$(zoxide init --cmd cd zsh)"

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

alias lsp="eza --tree --level=1 --icons=always -l --octal-permissions"
alias ls="eza --tree --level=1 --icons=always --no-time --no-user --no-permissions"
alias fd='fdfind'

# Если в системе нет batcat (Debian-нейминг), используем bat
if ! command -v batcat >/dev/null 2>&1 && command -v bat >/dev/null 2>&1; then
  alias batcat="bat"
fi

dumpctx() {
  local ignore_patterns=(
    ".git"
    ".vscode"
    "certs"
    "*.key"
    "*.crt"
    "*.pem"
    "*.env"
    ".venv"
    "settings.yml"
    "uv.lock"
  )

  local fd_exclude=()
  for pattern in "${ignore_patterns[@]}"; do
    fd_exclude+=(-E "$pattern")
  done

  local tmp_output
  tmp_output=$(mktemp)

  # Пишем всё во временный файл с ANSI-цветами
  fd --type f "${fd_exclude[@]}" "$@" | while read -r file; do
    echo "--- FILE: $file ---" >> "$tmp_output"
    batcat --style=plain --paging=never --color=always "$file" >> "$tmp_output"
    echo >> "$tmp_output"
  done

  local total_lines
  total_lines=$(wc -l < "$tmp_output")

  cat "$tmp_output"
  echo "📄 Всего строк выведено: $total_lines"

  rm -f "$tmp_output"
}
# ctx
# ctx -E Dockerfile
# ctx -d2

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

pathadd() {
    [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"
}
pathadd "$HOME/.local/bin"
pathadd "/usr/local/nvim/bin"

# Снипиты
alias ctx='dumpctx'
alias vsc='code . --reuse-window'
alias cat="bat --paging=never" #  --style=plain
alias lg='lazygit'

unalias llg 2>/dev/null
llg()
{
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir

    lazygit "$@"

    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
            cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
            rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
EOF

echo "Меняем дефолтный шелл на zsh..."
chsh -s "$(which zsh)"

echo "Установка завершена! Перезапусти терминал, чтобы начать использовать zsh с новым конфигом."
