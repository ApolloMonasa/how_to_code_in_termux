# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- learn more in https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# 我个人推荐 agnoster, powerlevel10k (需要单独安装字体), 或者 simple
# agnoster 主题会显示很多信息，包括当前目录、Git 状态等，非常实用
ZSH_THEME="agnoster"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Basic functionality will be enhanced to do case-insensitive completion.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable auto-update (not recommended).
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change the number of auto-update days.
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking dirty research git status.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to set a host name.
# export HOSTNAME="earth"

# Uncomment the following line if you want to disable command history sharing between sessions.
# DISABLE_HISTORY_SHARING="true"

# Uncomment the following line if you want to set a custom prompt.
# PROMPT="%{$fg[green]%}%n%{$reset_color%}@%{$fg[blue]%}%m%{$reset_color%} %{$fg[yellow]%}%~%{$reset_color%} %# "

# Uncomment the following line if you want to disable the ZSH_THEME_RANDOM_CANDIDATES functionality.
# ZSH_THEME_RANDOM_CANDIDATES=()

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(git nvim textmate ruby autojump)
# Add wisely, as too many plugins slow down shell startup.
# 我强烈推荐 git, zsh-autosuggestions, zsh-syntax-highlighting
plugins=(git
         zsh-autosuggestions
         zsh-syntax-highlighting
         # 其他你可能需要的插件，例如：
         # common-aliases # 常用别名，可以查看其源码了解
         # sudo # 按两次 ESC 自动在命令前添加 sudo
         # web-search # 方便地在终端进行网络搜索
         # extract # 方便解压各种文件
        )

source $ZSH/oh-my-zsh.sh

# User configuration
# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# export EDITOR="nvim"

# You may need to manually set your path if you have installed something from a custom prefix
# export PATH="/usr/local/bin:$PATH"

# Python alias (防止与系统 python 冲突，确保使用 Termux 的 python)
alias python='python3'
alias pip='pip3'

# Neovim 别名，确保在 zsh 中能直接启动 nvim
alias vim='nvim'
alias vi='nvim'

# FZF 配置 (如果安装了 FZF，用于模糊查找)
# if command -v fzf &> /dev/null; then
#   export FZF_DEFAULT_COMMAND='ag --nocolor -g ""' # 结合 ag (the_silver_searcher) 更快
#   export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
#   [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# fi

# Termux 特定配置
# ls 颜色
export LS_COLORS='di=1;34:ln=1;35:so=1;32:pi=1;33:ex=1;31:bd=1;36;01:cd=1;33;01:su=1;37;41:sg=1;30;43:tw=1;30;42:ow=1;37;44:*=0'