#!/bin/bash
set -e

# Проверяем, что это Fedora Linux
if [ ! -f /etc/fedora-release ]; then
    echo "Скрипт работает только на Fedora Linux. Выходим."
    exit 1
fi

echo "Обновляем систему и устанавливаем необходимые пакеты..."
sudo dnf upgrade --refresh -y
sudo dnf install -y zsh git zoxide neovim fzf curl fd-find bat dnf-plugins-core

echo "Подключаем Copr-репозитории для eza и lazygit..."
sudo dnf copr enable -y alternateved/eza
sudo dnf copr enable -y atim/lazygit

echo "Устанавливаем eza и lazygit..."
sudo dnf install -y eza lazygit

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

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

# История
setopt HIST_IGNORE_SPACE
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

HYPHEN_INSENSITIVE="true"

zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 14

DISABLE_AUTO_TITLE="true"
COMPLETION_WAITING_DOTS="true"

HIST_STAMPS="yyyy-mm-dd"

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

# Алиасы
alias lsp="eza --tree --level=1 --icons=always -l --octal-permissions"
alias ls="eza --tree --level=1 --icons=always --no-time --no-user --no-permissions"

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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

pathadd() {
    [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"
}
pathadd "$HOME/.local/bin"
pathadd "/usr/local/nvim/bin"

# Сниппеты / утилиты
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
