#!/bin/bash

# ======================================================================
# Termux C/C++/Python 开发环境一键配置脚本
# 版本: 1.5 (优先使用 Gitee 仓库下载配置文件)
# 作者: ApolloMonasa
# 日期: 2024-01-26
# 描述: 此脚本自动化配置 Termux 中的 C/C++/Python 开发环境，
#       包括 Neovim、COC.nvim、Treesitter 和 UltiSnips。
#       配置文件 (init.vim 和 pip.conf) 优先通过 Gitee 仓库下载，
#       提高脚本简洁性和可维护性，并优化国内访问速度。
# ======================================================================

echo "======================================================================"
echo " 正在启动 Termux 开发环境配置..."
echo " 此脚本将安装必要的软件包并配置 Neovim。"
echo " 请确保您有稳定的互联网连接。"
echo "======================================================================"

# --- 配置文件的远程 URL (优先使用 Gitee) ---
# !!! 请确保这些 URL 指向你的 Gitee 仓库中文件的 Raw 内容 !!!
# Gitee 的 Raw 内容链接通常格式为: https://gitee.com/用户名/仓库名/raw/分支名/文件路径
INIT_VIM_URL_GITEE="https://gitee.com/xyl6716/how_to_code_in_termux/raw/master/init.vim"
PIP_CONF_URL_GITEE="https://gitee.com/xyl6716/how_to_code_in_termux/raw/master/pip.conf" # 假设 pip.conf 也在此仓库

# Fallback 到 GitHub (如果 Gitee 访问失败)
INIT_VIM_URL_GITHUB="https://raw.githubusercontent.com/ApolloMonasa/how_to_code_in_termux/main/init.vim"
PIP_CONF_URL_GITHUB="https://raw.githubusercontent.com/ApolloMonasa/how_to_code_in_termux/main/pip.conf"

# --- 1. 更新 Termux 并安装基础软件包 ---
echo ""
echo "--- 步骤 1: 更新 Termux 并安装基础软件包 ---"
# 确保包管理器是最新的
pkg update -y
pkg upgrade -y

# 尝试安装 nodejs 和 npm
echo "尝试安装 Node.js 和 npm..."

# 优先尝试安装 nodejs-lts，它通常包含了 npm
pkg install -y nodejs-lts

# 检查 node (Node.js) 和 npm 是否都安装成功
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null
then
    echo "警告: nodejs-lts 未能通过 pkg install 成功安装或 npm 未找到。尝试安装普通的 nodejs 和 npm..."
    pkg install -y nodejs npm
    # 再次检查 node 和 npm 是否安装成功
    if ! command -v node &> /dev/null || ! command -v npm &> /dev/null
    then
        echo "错误: Node.js (和 npm) 无法安装。这可能是由于软件包源问题或Termux版本不兼容。"
        echo "请尝试以下操作："
        echo "  1. 运行 'termux-change-repo' 切换到默认源或尝试其他源。"
        echo "  2. 确保您的 Termux 应用是最新版本。"
        echo "  3. 手动尝试 'pkg install -y nodejs-lts' 或 'pkg install -y nodejs npm'"
        echo "如果问题持续存在，COC.nvim 将无法正常工作。退出脚本。"
        exit 1 # 如果Node.js是关键依赖，直接退出
    fi
fi

echo "Node.js 和 npm 已安装或已存在。"

# 安装其余的基础开发工具，包含 llvm 提供 clangd
echo "安装 C/C++/Python 开发所需的基础工具 (包括 llvm 以提供 clangd)..."
pkg install -y build-essential clang llvm python python-pip git neovim

if [ $? -ne 0 ]; then
    echo "错误: 基础软件包安装失败。退出脚本。"
    exit 1
fi
echo "基础软件包安装成功。"

# --- 2. 安装 Python 开发工具 ---
echo ""
echo "--- 步骤 2: 安装 Python 开发工具 (pip 包) ---"

# --- 2.1 询问是否配置 PyPI 镜像源 ---
read -p "是否需要配置 PyPI 镜像源（推荐中国大陆用户以加速下载，输入 y/n）? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    echo "正在配置 PyPI 镜像源..."
    mkdir -p ~/.pip

    echo "尝试从 Gitee 下载 pip.conf..."
    curl -fLo ~/.pip/pip.conf "$PIP_CONF_URL_GITEE"

    if [ $? -ne 0 ]; then
        echo "警告: 从 Gitee 下载 pip.conf 失败。尝试从 GitHub 下载..."
        curl -fLo ~/.pip/pip.conf "$PIP_CONF_URL_GITHUB"
        if [ $? -ne 0 ]; then
            echo "错误: 自动配置 PyPI 镜像源失败。请检查网络连接或提供的 URL 是否可访问。"
            echo "脚本将继续尝试安装，但如果下载遇到问题，可能需要手动配置或重试。"
        else
            echo "PyPI 镜像源从 GitHub 配置成功。"
        fi
    else
        echo "PyPI 镜像源从 Gitee 配置成功。"
    fi
else
    echo "跳过 PyPI 镜像源配置。"
fi

# 移除 pip --upgrade 命令，它在 Termux 中会导致问题
# pip install --upgrade pip # <--- 此行已被移除

# 安装 Neovim Python host provider 和 LSP 服务器
echo "正在安装 Python pip 包 (pynvim, python-lsp-server, black, flake8, isort)..."
pip install pynvim python-lsp-server black flake8 isort

if [ $? -ne 0 ]; then
    echo "错误: Python pip 包安装失败。请检查网络连接或 Termux Python 环境。"
    echo "如果问题持续存在，尝试手动运行 'pip install pynvim python-lsp-server black flake8 isort'"
    exit 1
fi
echo "Python 开发工具安装成功。"

# --- 3. 配置 Neovim ---
echo ""
echo "--- 步骤 3: 配置 Neovim ---"

# 创建 Neovim 配置目录
mkdir -p ~/.config/nvim

# 检查 Python 解释器路径 (可选，但推荐增强健壮性)
PYTHON_TERMUX_PATH="/data/data/com.termux/files/usr/bin/python"
if [ ! -f "$PYTHON_TERMUX_PATH" ]; then
    echo "警告: 无法找到 Python 解释器在 $PYTHON_TERMUX_PATH。"
    echo "Neovim Python provider 可能会有问题。请确保 'python' 包已正确安装。"
fi

# 通过 curl 下载 Neovim 配置文件 init.vim (优先从 Gitee 下载)
echo "正在从远程下载 Neovim 配置文件 init.vim..."
NVIM_CONFIG_FILE="$HOME/.config/nvim/init.vim"

echo "尝试从 Gitee 下载 init.vim..."
curl -fLo "$NVIM_CONFIG_FILE" "$INIT_VIM_URL_GITEE"

if [ $? -ne 0 ]; then
    echo "警告: 从 Gitee 下载 init.vim 失败。尝试从 GitHub 下载..."
    curl -fLo "$NVIM_CONFIG_FILE" "$INIT_VIM_URL_GITHUB"
    if [ $? -ne 0 ]; then
        echo "错误: Neovim 配置文件下载失败。请检查网络连接或提供的 URL 是否可访问。"
        echo "由于 init.vim 对 Neovim 配置至关重要，脚本将退出。"
        exit 1
    else
        echo "Neovim 配置文件从 GitHub 下载并创建在 $NVIM_CONFIG_FILE"
    fi
else
    echo "Neovim 配置文件从 Gitee 下载并创建在 $NVIM_CONFIG_FILE"
fi

echo "正在安装 vim-plug..."
# 安装 vim-plug (Neovim 插件管理器)
curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

if [ $? -ne 0 ]; then
    echo "错误: vim-plug 安装失败。退出脚本。"
    exit 1
fi
echo "vim-plug 安装成功。"

echo "正在安装 Neovim 插件... 这可能需要一些时间，请耐心等待。"
# 在静默模式下运行 nvim 来安装插件
nvim --headless +PlugInstall +qall

if [ $? -ne 0 ]; then
    echo "警告: 部分 Neovim 插件可能未能正确安装。请手动进入 Neovim 并运行 ':PlugInstall' 检查。"
fi
echo "Neovim 插件安装已启动。部分插件（如 coc.nvim 和 treesitter）需要进一步设置。"

# --- 4. Neovim 插件安装后的步骤 ---
echo ""
echo "--- 步骤 4: Neovim 插件安装后的步骤 ---"

# 安装 COC.nvim 扩展
echo "正在安装 COC.nvim 扩展 (coc-clangd, coc-pyright, etc.)... 这也可能需要一些时间。"
nvim --headless +":CocInstall coc-clangd coc-pyright coc-json coc-tsserver" +qall

if [ $? -ne 0 ]; then
    echo "警告: 部分 COC.nvim 扩展可能未能正确安装。请手动进入 Neovim 并运行 ':CocInstall coc-clangd coc-pyright coc-json coc-tsserver' 检查。"
fi
echo "COC.nvim 扩展安装已启动。"

# 更新 Treesitter 解析器 (确保 C, C++, Python 已安装)
echo "正在更新 nvim-treesitter 解析器..."
nvim --headless +":TSUpdate" +qall

if [ $? -ne 0 ]; then
    echo "警告: nvim-treesitter 解析器可能未能正确更新。请手动进入 Neovim 并运行 ':TSUpdate' 检查。"
fi
echo "nvim-treesitter 解析器更新已启动。"


echo ""
echo "======================================================================"
echo " Termux 开发环境配置完成!"
echo "======================================================================"
echo " 您现在可以在 Termux 终端中输入 'nvim' 来打开 Neovim。"
echo " 推荐的下一步操作:"
echo " 1. 在 Neovim 中运行 ':checkhealth' 来验证设置。"
echo " 2. 对于 Python: 创建一个 Python 文件 (.py) 并测试自动补全。"
echo " 3. 对于 C/C++: 创建一个 C/C++ 文件 (.c/.cpp) 并测试自动补全。"
echo " 祝您使用新的 Termux 开发环境愉快!"
echo "======================================================================"