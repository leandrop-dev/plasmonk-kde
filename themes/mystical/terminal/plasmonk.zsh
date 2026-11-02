# Plasmonk zsh setup. Adapted from Ryoku's ryoku.zsh (GPL-3.0, github.com/Ryoku-dev/ryoku):
# same tools and load order, without Ryoku's own services, and with colours from the
# Plasmonk palette. ~/.zshrc sources this file. Replaced on reinstall; put your own
# settings in ~/.config/zsh/user.zsh, which loads last.

[[ ${__PLASMONK_ZSH_LOADED:-0} == 1 ]] && return
__PLASMONK_ZSH_LOADED=1

# ~/.local/bin on PATH for every shell (plasmonk, cargo/go installs).
[[ -d $HOME/.local/bin && :$PATH: != *:$HOME/.local/bin:* ]] && export PATH="$HOME/.local/bin:$PATH"

[[ -o interactive ]] || return

# History, in case oh-my-zsh is missing (it sets its own otherwise).
HISTFILE=${HISTFILE:-$HOME/.zsh_history}
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_dups hist_ignore_space

# System readout on terminal open, coloured by the palette.
command -v fastfetch >/dev/null 2>&1 && fastfetch

_plasmonk_cfg=${XDG_CONFIG_HOME:-$HOME/.config}
_plasmonk_prompt=${PLASMONK_ZSH_PROMPT:-starship}
_plasmonk_omz=0
if [[ -r ${ZSH:-/usr/share/oh-my-zsh}/oh-my-zsh.sh ]]; then
  export ZSH=${ZSH:-/usr/share/oh-my-zsh}
  export ZSH_CUSTOM=${ZSH_CUSTOM:-$_plasmonk_cfg/zsh/oh-my-zsh}
  DISABLE_AUTO_UPDATE=true
  ZSH_COMPDUMP=${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump
  mkdir -p "${ZSH_COMPDUMP:h}"
  (( ${+plugins} )) || plugins=(git)
  if [[ $_plasmonk_prompt == oh-my-zsh ]]; then
    : ${ZSH_THEME:=robbyrussell}
  else
    ZSH_THEME=""
  fi
  source "$ZSH/oh-my-zsh.sh"
  _plasmonk_omz=1
fi

if [[ $_plasmonk_prompt != oh-my-zsh || $_plasmonk_omz != 1 ]]; then
  command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
fi
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh --cmd cd)"
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh)"
command -v fzf >/dev/null 2>&1 && eval "$(fzf --zsh)"

# fzf walks the tree via fd when present.
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

if (( ! _plasmonk_omz )); then
  autoload -Uz compinit
  mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
fi

_plasmonk_source_first() {
  local f
  for f in "$@"; do
    if [[ -r $f ]]; then
      source "$f"
      return
    fi
  done
  return 1
}
_plasmonk_source_first /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh || true
# history-substring-search must load after syntax-highlighting (per its README).
_plasmonk_source_first /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh || true
_plasmonk_source_first /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh || true
unset -f _plasmonk_source_first

# Highlight colours, rendered from the palette by `plasmonk apply`.
[[ -r $_plasmonk_cfg/zsh/plasmonk-colors.zsh ]] && source "$_plasmonk_cfg/zsh/plasmonk-colors.zsh"

if (( $+functions[history-substring-search-up] )); then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
  bindkey '^P' history-substring-search-up
  bindkey '^N' history-substring-search-down
fi

if command -v eza >/dev/null 2>&1; then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi

[[ -r $_plasmonk_cfg/zsh/user.zsh ]] && source "$_plasmonk_cfg/zsh/user.zsh"

unset _plasmonk_prompt _plasmonk_omz _plasmonk_cfg
