#!/bin/bash

# ======================================================================
# Termux C/C++/Python Development Environment Setup Script
# Version: 1.0
# Author: Your Name (或保留为空)
# Date: 2023-10-27
# Description: This script automates the setup of C/C++/Python
#              development environment in Termux, including Neovim
#              with COC.nvim, Treesitter, and UltiSnips.
# ======================================================================

echo "======================================================================"
echo " Starting Termux Development Environment Setup"
echo " This script will install necessary packages and configure Neovim."
echo " Please ensure you have a stable internet connection."
echo "======================================================================"

# --- 1. System Update and Essential Packages ---
echo ""
echo "--- Step 1: Updating Termux and installing essential packages ---"
pkg update -y
pkg upgrade -y
pkg install -y build-essential clang python python-pip git neovim nodejs npm
# build-essential for common build tools like make, gcc (already included with clang on Termux)
# clang for C/C++ compiler
# python/python-pip for Python development
# git for cloning repositories
# neovim as the editor
# nodejs/npm for coc.nvim extensions

if [ $? -ne 0 ]; then
    echo "Error: Failed to install essential packages. Exiting."
    exit 1
fi
echo "Essential packages installed successfully."

# --- 2. Install Python Development Tools ---
echo ""
echo "--- Step 2: Installing Python development tools (pip packages) ---"
pip install --upgrade pip
pip install pynvim # Neovim Python host provider
pip install python-lsp-server # Python Language Server for COC.nvim (pylsp)
pip install black flake8 isort # Common Python formatters/linters

if [ $? -ne 0 ]; then
    echo "Error: Failed to install Python pip packages. Exiting."
    exit 1
fi
echo "Python development tools installed successfully."

# --- 3. Configure Neovim ---
echo ""
echo "--- Step 3: Configuring Neovim ---"

# Create Neovim configuration directory
mkdir -p ~/.config/nvim

# Create init.vim file and populate with the provided configuration
NVIM_CONFIG_FILE="$HOME/.config/nvim/init.vim"
cat << EOF > "$NVIM_CONFIG_FILE"
" ======================================================================
" Neovim Configuration for Termux (C/C++/Python) - 完整版
" ======================================================================

" --- Python Provider for Neovim ---
" 显式指定 Termux 中 Python 3 解释器的路径，确保 UltiSnips 和其他 Python 插件正常工作
let g:python3_host_prog = '/data/data/com.termux/files/usr/bin/python'
let g:python_host_prog = '/data/data/com.termux/files/usr/bin/python'

" --- 禁用不需要的 Provider (消除 checkhealth 警告) ---
" 如果不需要 Ruby 或 Perl 开发，可以禁用这些 provider
let g:loaded_ruby_provider = 0
let g:loaded_perl_provider = 0
let g:loaded_node_provider = 0 " Node.js provider在coc.nvim中使用，这里不应禁用，而是安装npm包

" --- Plugin Manager: vim-plug ---
call plug#begin('~/.config/nvim/plugged')

" General Enhancements
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'} " 语法高亮 (Treesitter)
Plug 'gruvbox-community/gruvbox' " 主题颜色 (Colorscheme)

" Autocompletion Engine (非常强大，基于 LSP)
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Snippet Engine and Snippets (代码模板)
Plug 'SirVer/ultisnips' " Snippet 引擎
Plug 'honza/vim-snippets' " 常用代码片段集合

" Indentation & Formatting (缩进和格式化)
Plug 'Chiel92/vim-autoformat' " 自动格式化插件
Plug 'jiangmiao/auto-pairs' " 括号、引号自动补全

" File Explorer (可选但非常有用)
Plug 'preservim/nerdtree' " 文件浏览器

" Git Integration (可选)
Plug 'tpope/vim-fugitive' " Git 命令封装

call plug#end()

" ======================================================================
" --- General Settings ---
" ======================================================================
set nocompatible " 兼容性设置，必须
filetype plugin indent on " 启用文件类型检测、插件和智能缩进
syntax enable " 启用语法高亮
set encoding=utf-8 " 设置默认编码为 UTF-8
set tabstop=4 " 一个 Tab 键代表的空格数
set shiftwidth=4 " 自动缩进的空格数
set expandtab " Tab 键输入时转换为空格
set autoindent " 从上一行复制缩进
set smartindent " 更智能的自动缩进
set number " 显示行号
set relativenumber " 显示相对行号
set cursorline " 高亮当前行
set ttyfast " 加速终端屏幕更新
set showmatch " 高亮匹配的括号
set incsearch " 实时搜索
set hlsearch " 高亮所有搜索匹配
set noerrorbells " 关闭错误响铃
set visualbell " 闪屏代替响铃
set wrap " 自动换行
set backspace=indent,eol,start " 使退格键在插入模式下行为更自然
set completeopt=menuone,noselect " 补全菜单选项
set signcolumn=yes " 总是显示符号列 (例如用于 linting 错误)

" --- Clipboard Integration (剪贴板集成) ---
" 仅在 Termux 环境下启用系统剪贴板
if has('termux')
    set clipboard=unnamedplus
endif

" --- Colorscheme ---
colorscheme gruvbox
set background=dark " 或 'light'，根据个人喜好

" ======================================================================
" --- Plugin Specific Configurations ---
" ======================================================================

" --- Neovim Treesitter (Syntax Highlighting) ---
lua << EOL
require('nvim-treesitter.configs').setup {
  ensure_installed = { "c", "cpp", "python" }, -- 安装 C, C++, Python 的解析器
  highlight = {
    enable = true,
    disable = {},
  },
  indent = { enable = true },
}
EOL

" --- COC.nvim (Completion Engine) ---
" Basic COC configuration for C/C++/Python
" For C/C++: Install `clangd`
" For Python: Install `pylsp` (Python Language Server)
" See :help coc-configuration for more details.
let g:coc_global_extensions = ['coc-clangd', 'coc-pyright', 'coc-json', 'coc-tsserver']
" For JavaScript/TypeScript  (将注释移到列表定义下方)

" --- COC.nvim Tab 键智能行为 (补全和代码片段) ---
" 这个配置尝试智能处理 Tab 键的行为：
" 1. 补全菜单弹出时，按 Tab 键选择下一个补全项。
" 2. 如果没有补全菜单，但是 UltiSnips 有可展开的片段，按 Tab 键展开片段。
" 3. 如果没有补全菜单，也不是片段，且光标前是空白，按 Tab 键插入 Tab/空格。
" 4. 否则，按 Tab 键尝试触发 CoC 补全。
function! CocTabBehavior() abort
  if coc#pum#visible() " 补全菜单可见
    return coc#pum#next() " 选择下一个补全项
  endif
  if exists('*UltiSnips#CanExpandSnippet') && UltiSnips#CanExpandSnippet() " UltiSnips 可展开
    return "\<Plug>(ultisnips-expand)" " 展开 UltiSnips 片段
  endif
  if exists('*UltiSnips#CanJumpNext') && UltiSnips#CanJumpNext() " UltiSnips 可跳转到下一个占位符
    return "\<Plug>(ultisnips-jump-next)"
  endif
  " 如果光标前是空白，插入 Tab，否则触发 CoC 补全
  if col('.') <= 1 || getline('.')[col('.')-2] =~ '\s'
    return "\<Tab>"
  else
    return coc#refresh()
  endif
endfunction

inoremap <silent><expr> <TAB> <SID>CocTabBehavior()

" Shift+Tab 键的智能行为 (补全和代码片段)
function! CocShiftTabBehavior() abort
  if coc#pum#visible() " 补全菜单可见
    return coc#pum#prev() " 选择上一个补全项
  endif
  if exists('*UltiSnips#CanJumpPrev') && UltiSnips#CanJumpPrev() " UltiSnips 可跳转到上一个占位符
    return "\<Plug>(ultisnips-jump-prev)"
  endif
  return "\<C-h>" " 否则，插入退格 (通常作为 Shift+Tab 的默认行为)
endfunction

inoremap <silent><expr> <S-TAB> <SID>CocShiftTabBehavior()

" 使用 <CR> (回车键) 确认补全或跳到片段下一个占位符
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"
" 定义快捷键来触发代码格式化（使用 vim-autoformat）
nnoremap <leader>f :Autoformat<CR>
vnoremap <leader>f :Autoformat<CR>

" NERDTree 快捷键
map <leader>n :NERDTreeToggle<CR> " 切换 NERDTree
" FZF 快捷键（如果安装了 FZF，虽然脚本中没有显式安装，但用户可能需要）
" nnoremap <leader>f :Files<CR>
" nnoremap <leader>g :GFiles<CR>

" UltiSnips 配置
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"

" COC.nvim 错误和警告符号
sign define CocWarningText text=Warn texthl=CocWarningSign
sign define CocErrorText text=Error texthl=CocErrorSign

" 设置诊断显示方式
set signcolumn=yes:1

" 定义 leader 键 (例如空格键)
let mapleader = " "

" 其他常用的 COC 映射 (可以根据需要取消注释或添加)
" nnoremap <silent> gd <Plug>(coc-definition)
" nnoremap <silent> gy <Plug>(coc-type-definition)
" nnoremap <silent> gi <Plug>(coc-implementation)
" nnoremap <silent> gr <Plug>(coc-references)
" nnoremap <silent> K :call <SID>show_documentation()<CR>

" function! <SID>show_documentation()
"   if (index(['vim','help'], &filetype) >= 0)
"     execute 'h '.expand('<cword>')
"   elseif (coc#rpc#ready())
"     call CocActionAsync('doHover')
"   else
"     execute '!' . &keywordprg . " " . expand('<cword>')
"   endif
" endfunction

" 自动修复
" nnoremap <silent> <leader>q :call CocAction('fixAll')<CR>

" 重命名
" nnoremap <leader>rn <Plug>(coc-rename)

EOF

if [ $? -ne 0 ]; then
    echo "Error: Failed to create Neovim configuration file. Exiting."
    exit 1
fi
echo "Neovim configuration file created at $NVIM_CONFIG_FILE"
echo "Installing vim-plug..."

# Install vim-plug (Neovim plugin manager)
curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

if [ $? -ne 0 ]; then
    echo "Error: Failed to install vim-plug. Exiting."
    exit 1
fi
echo "vim-plug installed successfully."

echo "Installing Neovim plugins... This may take some time."
# Run nvim in silent mode to install plugins
nvim --headless +PlugInstall +qall

if [ $? -ne 0 ]; then
    echo "Warning: Some Neovim plugins might not have installed correctly. Please check manually."
fi
echo "Neovim plugins installation initiated. Some plugins like coc.nvim and treesitter require further setup."

# --- 4. Post-Neovim Plugin Installation Steps ---
echo ""
echo "--- Step 4: Post-Neovim Plugin Installation Steps ---"

# Install COC.nvim extensions
echo "Installing COC.nvim extensions (coc-clangd, coc-pyright, etc.)..."
nvim --headless +":CocInstall coc-clangd coc-pyright coc-json coc-tsserver" +qall

if [ $? -ne 0 ]; then
    echo "Warning: Some COC.nvim extensions might not have installed correctly. Please check manually."
fi
echo "COC.nvim extensions installation initiated."

# Update Treesitter parsers (ensure C, C++, Python are installed)
echo "Updating nvim-treesitter parsers..."
nvim --headless +":TSUpdate" +qall

if [ $? -ne 0 ]; then
    echo "Warning: nvim-treesitter parsers might not have updated correctly. Please check manually."
fi
echo "nvim-treesitter parsers update initiated."


echo ""
echo "======================================================================"
echo " Termux Development Environment Setup Complete!"
echo "======================================================================"
echo " You can now open Neovim by typing 'nvim' in your Termux terminal."
echo " Recommended next steps:"
echo " 1. Run ':checkhealth' in Neovim to verify setup."
echo " 2. For Python: Try to create a Python file (.py) and test autocompletion."
echo " 3. For C/C++: Try to create a C/C++ file (.c/.cpp) and test autocompletion."
echo " Enjoy your new Termux development environment!"
echo "======================================================================"

# You can add an image here if you want to show a completion message visually
#