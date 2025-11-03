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
" 注意: g:loaded_node_provider 通常不应禁用，因为 COC.nvim 依赖 Node.js。
" 如果禁用，coc.nvim 及其一些扩展可能会无法工作。
" let g:loaded_node_provider = 0 

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
lua << EOF
require('nvim-treesitter.configs').setup {
  ensure_installed = { "c", "cpp", "python" }, -- 安装 C, C++, Python 的解析器
  highlight = {
    enable = true,
    disable = {},
  },
  indent = { enable = true },
}
EOF

" --- COC.nvim (Completion Engine) ---
" Basic COC configuration for C/C++/Python
" For C/C++: Install `clangd`
" For Python: Install `pylsp` (Python Language Server)
" See :help coc-configuration for more details.
let g:coc_global_extensions = ['coc-clangd', 'coc-pyright', 'coc-json', 'coc-tsserver']
" coc-tsserver for JavaScript/TypeScript development.

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
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>"

" 手动触发补全
inoremap <silent><expr> <c-space> coc#refresh()

" 自动高亮光标下的符号
autocmd CursorHold * silent call CocActionAsync('highlight')

" --- Ultisnips (Snippets) ---
" 这里的 UltiSnips 触发键已被上面的 CocTabBehavior 涵盖，所以可以注释或删除默认的触发键设置
" let g:UltiSnipsExpandTrigger="<tab>"
" let g:UltiSnipsJumpForwardTrigger="<tab>"
" let g:UltiSnipsJumpBackwardTrigger="<s-tab>"

" --- Autoformat (自动格式化) ---
" 你需要安装对应的格式化工具:
" For C/C++: pkg install -y clang-format
" For Python: pip install black (推荐) 或 pip install autopep8
" 取消注释下面这行可以在保存时自动格式化
" autocmd BufWritePre *.c,*.cpp,*.py,*.js,*.ts,*.json call Autoformat()

" --- NERDTree (文件浏览器) ---
map <C-n> :NERDTreeToggle<CR> " 使用 Ctrl+n 切换 NERDTree

" ======================================================================
" --- Custom Key Mappings (自定义快捷键) ---
" ======================================================================
" 定义 leader 键 (例如空格键)
let mapleader = " "

" 快速退出插入模式
inoremap jj <esc>

" 快速保存
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :wq<CR>