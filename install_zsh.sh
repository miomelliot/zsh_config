#!/bin/bash
set -euo pipefail

# --- Checks -------------------------------------------------------------------
if [[ ! -f /etc/arch-release ]]; then
  echo "Скрипт рассчитан на Arch Linux."; exit 1
fi

# --- Packages -----------------------------------------------------------------
echo "==> Обновляем систему и устанавливаем пакеты"
sudo pacman -Syu --noconfirm --needed zsh git curl neovim zoxide eza fzf fd bat

# --- Paths --------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"

# --- oh-my-zsh ----------------------------------------------------------------
if [[ ! -d "$ZSH" ]]; then
  echo "==> Устанавливаем oh-my-zsh"
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$ZSH"
fi

# --- Powerlevel10k ------------------------------------------------------------
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
  echo "==> Устанавливаем Powerlevel10k"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$ZSH_CUSTOM/themes/powerlevel10k"
fi

# --- Plugins ------------------------------------------------------------------
install_plugin() {
  local repo="$1" dest="$2"
  if [[ ! -d "$dest" ]]; then
    echo "==> Плагин: $repo"
    git clone --depth=1 "$repo" "$dest"
  fi
}

install_plugin https://github.com/zsh-users/zsh-autosuggestions           "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
install_plugin https://github.com/zsh-users/zsh-history-substring-search  "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
install_plugin https://github.com/zsh-users/zsh-syntax-highlighting       "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
install_plugin https://github.com/zsh-users/zsh-completions               "$ZSH_CUSTOM/plugins/zsh-completions"
install_plugin https://github.com/matthiasha/zsh-uv-env                   "$ZSH_CUSTOM/plugins/zsh-uv-env"

# Кастомный плагин uv (completions для uv/uvx)
if [[ ! -d "$ZSH_CUSTOM/plugins/uv" ]]; then
  echo "==> Создаём кастомный плагин uv"
  mkdir -p "$ZSH_CUSTOM/plugins/uv"
  cat > "$ZSH_CUSTOM/plugins/uv/uv.plugin.zsh" <<'PLUG'
# uv plugin: completions
if command -v uv >/dev/null 2>&1; then
  eval "$(uv generate-shell-completion zsh)" 2>/dev/null
fi
if command -v uvx >/dev/null 2>&1; then
  eval "$(uvx --generate-shell-completion zsh)" 2>/dev/null
fi
PLUG
fi

# --- UV -----------------------------------------------------------------------
if ! command -v uv >/dev/null 2>&1; then
  echo "==> Устанавливаем uv"
  curl -LsSf https://astral.sh/uv/install.sh | sh
else
  echo "==> Обновляем uv (если доступно)"
  uv self update || true
fi

# --- NVM ----------------------------------------------------------------------
if ! command -v nvm >/dev/null 2>&1; then
  echo "==> Устанавливаем nvm"
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
fi

# --- .zshrc -------------------------------------------------------------------
if [[ -f "$HOME/.zshrc" ]]; then
  cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
fi

echo "==> Пишем ~/.zshrc"
cat > "$HOME/.zshrc" <<'EOF'
# Enable Powerlevel10k instant prompt (должно быть вверху).
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# История
setopt HIST_IGNORE_SPACE
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
HIST_STAMPS="yyyy-mm-dd"

# Поведение omz
HYPHEN_INSENSITIVE="true"
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 14
DISABLE_AUTO_TITLE="true"
COMPLETION_WAITING_DOTS="true"

# Плагины
plugins=(
  git
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-syntax-highlighting     # должен загружаться последним среди подсветок
  zsh-completions
  fzf
  uv                          # кастомный плагин ($ZSH_CUSTOM/plugins/uv)
  zsh-uv-env
)
source $ZSH/oh-my-zsh.sh

# zoxide
eval "$(zoxide init --cmd cd zsh)"

# Определяем корректные имена бинарей bat/fd (для переносимости)
if command -v batcat >/dev/null 2>&1; then BAT_CMD=batcat; else BAT_CMD=bat; fi
if command -v fdfind  >/dev/null 2>&1; then FD_CMD=fdfind; else FD_CMD=fd;  fi

# Алиасы
alias lsp="eza --tree --level=1 --icons=always -l --octal-permissions"
alias ls="eza --tree --level=1 --icons=always --no-time --no-user --no-permissions"
alias fd="$FD_CMD"
alias cat="$BAT_CMD --paging=never"
alias ctx='dumpctx'
alias vsc='code . --reuse-window'
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# PATH
pathadd() { [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH"; }
pathadd "$HOME/.local/bin"
pathadd "/usr/local/nvim/bin"

# NVM
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"

# Сниппеты
dumpctx() {
  local ignore_patterns=(
    ".git" ".vscode" "certs" "*.key" "*.crt" "*.pem" "*.env" ".venv"
    "settings.yml" "uv.lock"
  )
  local fd_exclude=()
  for p in "${ignore_patterns[@]}"; do fd_exclude+=(-E "$p"); done
  local tmp_output; tmp_output=$(mktemp)
  $FD_CMD --type f "${fd_exclude[@]}" "$@" | while read -r file; do
    echo "--- FILE: $file ---" >> "$tmp_output"
    $BAT_CMD --style=plain --paging=never --color=always "$file" >> "$tmp_output"
    echo >> "$tmp_output"
  done
  local total_lines; total_lines=$(wc -l < "$tmp_output")
  cat "$tmp_output"
  echo "📄 Всего строк выведено: $total_lines"
  rm -f "$tmp_output"
}

# Локальные окружения
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
EOF

# --- Login shell --------------------------------------------------------------
echo "==> Делаем zsh логином по умолчанию"
ZSH_BIN="$(command -v zsh)"
if [[ -z "$ZSH_BIN" ]]; then
  echo "zsh не найден в PATH"; exit 1
fi

# гарантируем наличие пути в /etc/shells
if [[ ! -f /etc/shells ]]; then
  sudo touch /etc/shells
fi
if ! grep -qx "$ZSH_BIN" /etc/shells; then
  echo "==> Добавляю $ZSH_BIN в /etc/shells"
  echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
fi

# меняем shell, если он ещё не zsh
current_shell="$(getent passwd "$USER" | cut -d: -f7 || true)"
if [[ "$current_shell" != "$ZSH_BIN" ]]; then
  if chsh -s "$ZSH_BIN"; then
    echo "==> chsh: OK"
  else
    echo "==> chsh не удался, пробую usermod"
    sudo usermod -s "$ZSH_BIN" "$USER" || {
      echo "Не удалось задать shell. Установите вручную: chsh -s $ZSH_BIN"; exit 1; }
  fi
fi

echo "Готово. Перезапусти терминал (или перелогинься) и проверь: echo \$SHELL"
