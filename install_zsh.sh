#!/bin/bash
set -e

# Проверяем, что это Arch Linux
if [ ! -f /etc/arch-release ]; then
    echo "Скрипт работает только на Arch Linux. Выходим."
    exit 1
fi

echo "Обновляем систему и устанавливаем необходимые пакеты..."
sudo pacman -Syu --noconfirm zsh git zoxide eza neovim fzf curl

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
install_plugin https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
install_plugin https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
install_plugin https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
install_plugin https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"

# Устанавливаем UV по официальной инструкции
if ! command -v uv >/dev/null 2>&1; then
    echo "UV не найден – устанавливаем..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
else
    echo "UV уже установлен – обновляем..."
fi
uv self update || echo "Обновление UV не удалось, возможно uv не установлен корректно."

# Устанавливаем NVM, если не установлен
if [ -z "$(command -v nvm)" ]; then
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
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Тема Powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# История: игнор команд с пробелом, сразу добавлять, разделять сессии и не дублировать
setopt HIST_IGNORE_SPACE
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# Плагины
plugins=(
  git
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-syntax-highlighting
  zsh-completions
  fzf
  uv
)

source $ZSH/oh-my-zsh.sh

# Инициализация zoxide (после Oh My Zsh)
eval "$(zoxide init --cmd cd zsh)"

# User configuration

alias ls="eza --tree --level=1 --icons=always --no-time --no-user --no-permissions"
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

pathadd() {
    [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"
}
pathadd "$HOME/.local/bin"
pathadd "/usr/local/nvim/bin"

alias vsc='code . --reuse-window'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"
EOF

echo "Меняем дефолтный шелл на zsh..."
chsh -s "$(which zsh)"

echo "Установка завершена! Перезапусти терминал, чтобы начать использовать zsh с новым конфигом."
