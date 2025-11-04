#!/bin/bash

# ======================================================================
# Termux C/C++/Python/Zsh 开发环境一键配置脚本
# 版本: 1.7 (增强稳定性、覆盖策略和 Zsh 插件安装)
# 作者: ApolloMonasa (由 AI 助理优化)
# 日期: 2024-01-27
# 描述: 此脚本自动化配置 Termux 中的 C/C++/Python 开发环境，
#       包括 Neovim、COC.nvim、Treesitter 和 UltiSnips。
#       同时集成 Zsh 和 Oh My Zsh 进行终端美化，并增强插件管理。
#       所有配置文件优先通过 Gitee 仓库下载，提高国内访问速度。
# ======================================================================

echo "======================================================================"
echo " 正在启动 Termux 开发环境配置..."
echo " 此脚本将安装必要的软件包并配置 Neovim 和 Zsh。"
echo " 请确保您有稳定的互联网连接。"
echo "======================================================================"

# --- 配置文件的远程 URL (优先使用 Gitee) ---
# !!! 请确保这些 URL 指向你的 Gitee 仓库中文件的 Raw 内容 !!!
# Gitee 的 Raw 内容链接通常格式为: https://gitee.com/用户名/仓库名/raw/分支名/文件路径
REPO_BASE_GITEE="https://gitee.com/xyl6716/how_to_code_in_termux/raw/master"
INIT_VIM_URL_GITEE="$REPO_BASE_GITEE/init.vim"
PIP_CONF_URL_GITEE="$REPO_BASE_GITEE/pip.conf"
ZSHRC_URL_GITEE="$REPO_BASE_GITEE/.zshrc"

# Fallback 到 GitHub (如果 Gitee 访问失败)
REPO_BASE_GITHUB="https://raw.githubusercontent.com/ApolloMonasa/how_to_code_in_termux/main"
INIT_VIM_URL_GITHUB="$REPO_BASE_GITHUB/init.vim"
PIP_CONF_URL_GITHUB="$REPO_BASE_GITHUB/pip.conf"
ZSHRC_URL_GITHUB="$REPO_BASE_GITHUB/.zshrc"

# --- 辅助函数：下载文件 ---
download_file() {
    local GITHUB_URL=$1
    local GITEE_URL=$2
    local DEST_PATH=$3
    local FILE_DESCRIPTION=$4

    echo "尝试从 Gitee 下载 $FILE_DESCRIPTION..."
    curl -fLo "$DEST_PATH" "$GITEE_URL" &>/dev/null # 静默下载，只打印错误

    if [ $? -ne 0 ]; then
        echo "警告: 从 Gitee 下载 $FILE_DESCRIPTION 失败。尝试从 GitHub 下载..."
        curl -fLo "$DEST_PATH" "$GITHUB_URL" &>/dev/null

        if [ $? -ne 0 ]; then
            echo "错误: $FILE_DESCRIPTION 下载失败。请检查网络连接或提供的 URL 是否可访问。"
            return 1 # 返回失败
        else
            echo "$FILE_DESCRIPTION 从 GitHub 下载成功并已覆盖。"
        fi
    else
        echo "$FILE_DESCRIPTION 从 Gitee 下载成功并已覆盖。"
    fi
    return 0 # 返回成功
}

# --- 辅助函数：克隆或更新 Git 仓库 ---
clone_or_update_repo() {
    local GITHUB_URL=$1
    local GITEE_URL=$2
    local DEST_PATH=$3
    local REPO_DESCRIPTION=$4

    echo "正在处理 $REPO_DESCRIPTION 仓库..."
    if [ -d "$DEST_PATH/.git" ]; then
        echo "  - $REPO_DESCRIPTION 已存在，尝试更新..."
        (cd "$DEST_PATH" && git pull --ff-only &>/dev/null) # 静默更新
        if [ $? -ne 0 ]; then
            echo "  警告: 更新 $REPO_DESCRIPTION 失败。可能是网络问题或本地修改。将跳过更新。"
        else
            echo "  - $REPO_DESCRIPTION 更新成功。"
        fi
    else
        echo "  - $REPO_DESCRIPTION 不存在或不是 Git 仓库，尝试从 Gitee 克隆..."
        git clone "$GITEE_URL" "$DEST_PATH" &>/dev/null # 静默克隆
        if [ $? -ne 0 ]; then
            echo "  警告: 从 Gitee 克隆 $REPO_DESCRIPTION 失败。尝试从 GitHub 克隆..."
            git clone "$GITHUB_URL" "$DEST_PATH" &>/dev/null
            if [ $? -ne 0 ]; then
                echo "  错误: 克隆 $REPO_DESCRIPTION 失败。请检查网络连接。"
                return 1
            else
                echo "  - $REPO_DESCRIPTION 从 GitHub 克隆成功。"
            fi
        else
            echo "  - $REPO_DESCRIPTION 从 Gitee 克隆成功。"
        fi
    fi
    return 0
}


# --- 1. 更新 Termux 并安装基础软件包 ---
echo ""
echo "--- 步骤 1: 更新 Termux 并安装基础软件包 ---"
pkg update -y && pkg upgrade -y
if [ $? -ne 0 ]; then
    echo "错误: Termux 更新或升级失败。请检查网络连接或存储空间。退出脚本。"
    exit 1
fi
echo "Termux 更新和升级成功。"

# 尝试安装 nodejs 和 npm
echo "尝试安装 Node.js 和 npm..."
pkg install -y nodejs-lts
# 检查 node (Node.js) 和 npm 是否都安装成功
if ! command -v node &> /dev/null || ! command -v npm &> /dev/null
then
    echo "警告: nodejs-lts 未能通过 pkg install 成功安装或 npm 未找到。尝试安装普通的 nodejs 和 npm..."
    pkg install -y nodejs npm
    if ! command -v node &> /dev/null || ! command -v npm &> /dev/null
    then
        echo "致命错误: Node.js (和 npm) 无法安装。COC.nvim 将无法正常工作。退出脚本。"
        echo "请尝试 'termux-change-repo' 切换源，或手动安装 'pkg install -y nodejs-lts'。"
        exit 1
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
echo # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "正在配置 PyPI 镜像源..."
    mkdir -p ~/.pip
    if ! download_file "$PIP_CONF_URL_GITHUB" "$PIP_CONF_URL_GITEE" "$HOME/.pip/pip.conf" "pip.conf 配置文件"; then
        echo "PyPI 镜像源配置失败。脚本将继续，但 pip 下载速度可能较慢。"
    fi
else
    echo "跳过 PyPI 镜像源配置。"
fi

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
mkdir -p ~/.config/nvim/autoload
echo "Neovim 配置目录已创建或已存在。"

# 下载 Neovim 配置文件 init.vim
NVIM_CONFIG_FILE="$HOME/.config/nvim/init.vim"
if ! download_file "$INIT_VIM_URL_GITHUB" "$INIT_VIM_URL_GITEE" "$NVIM_CONFIG_FILE" "Neovim 配置文件 init.vim"; then
    echo "致命错误: Neovim 配置文件下载失败。由于 init.vim 对 Neovim 配置至关重要，脚本将退出。"
    exit 1
fi

# 安装 vim-plug
VIM_PLUG_INSTALL_PATH="$HOME/.config/nvim/autoload/plug.vim"
VIM_PLUG_URL_GITEE="https://gitee.com/yanglbme/vim-plug/raw/master/plug.vim" # Gitee 镜像源
VIM_PLUG_URL_GITHUB="https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" # GitHub 官方源
if ! download_file "$VIM_PLUG_URL_GITHUB" "$VIM_PLUG_URL_GITEE" "$VIM_PLUG_INSTALL_PATH" "vim-plug"; then
    echo "致命错误: vim-plug 安装失败。Neovim 插件将无法管理。退出脚本。"
    exit 1
fi

# --- 关键调整在这里 ---
echo "正在安装 Neovim 插件... 这可能需要一些时间，请耐心等待。请勿关闭终端或强制退出。"
nvim --headless +PlugInstall +UpdateRemotePlugins +qall
if [ $? -ne 0 ]; then
    echo "警告: Neovim 插件安装过程可能存在问题。建议手动进入 Neovim，运行 ':PlugInstall' 和 ':checkhealth' 检查。"
fi
echo "插件安装命令已发送。等待 10 秒，确保所有后台任务完成..."
sleep 10
echo "Neovim 插件安装命令已执行。下一步将安装 COC.nvim 扩展。"

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

# --- 5. 配置 Zsh 和 Oh My Zsh (可选美化) ---
echo ""
echo "--- 步骤 5: 配置 Zsh 和 Oh My Zsh (可选美化) ---"

read -p "是否需要安装 Zsh 和 Oh My Zsh 进行终端美化（推荐，输入 y/n）? " -n 1 -r
echo # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "正在安装 Zsh..."
    pkg install -y zsh
    if [ $? -ne 0 ]; then
        echo "错误: Zsh 安装失败。跳过 Oh My Zsh 配置。"
    else
        echo "Zsh 安装成功。正在安装 Oh My Zsh..."

        if [ -d "$HOME/.oh-my-zsh" ]; then
            echo "Oh My Zsh 目录已存在。尝试更新。"
            # Oh My Zsh 自身可以通过其内置机制更新，这里不强制 git pull
        else
            echo "Oh My Zsh 正在首次安装..."
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            if [ $? -ne 0 ]; then
                echo "错误: Oh My Zsh 安装失败。请检查网络连接。跳过后续 Zsh 配置。"
                exit 1
            fi
            echo "Oh My Zsh 首次安装成功。"
        fi

        echo "正在配置 .zshrc..."
        if ! download_file "$ZSHRC_URL_GITHUB" "$ZSHRC_URL_GITEE" "$HOME/.zshrc" ".zshrc 配置文件"; then
            echo "错误: .zshrc 配置文件下载失败。Oh My Zsh 将使用默认配置。"
        fi

        # 安装推荐的插件
        echo "正在安装 zsh-syntax-highlighting 和 zsh-autosuggestions 插件..."
        PLUGIN_CUSTOM_PATH="$HOME/.oh-my-zsh/custom/plugins"
        mkdir -p "$PLUGIN_CUSTOM_PATH"

        # zsh-syntax-highlighting
        clone_or_update_repo \
            "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
            "https://gitee.com/Annihilater/zsh-syntax-highlighting.git" \
            "$PLUGIN_CUSTOM_PATH/zsh-syntax-highlighting" \
            "zsh-syntax-highlighting"

        # zsh-autosuggestions
        clone_or_update_repo \
            "https://github.com/zsh-users/zsh-autosuggestions.git" \
            "https://gitee.com/Annihilater/zsh-autosuggestions.git" \
            "$PLUGIN_CUSTOM_PATH/zsh-autosuggestions" \
            "zsh-autosuggestions"

        echo "Oh My Zsh 插件安装/更新已尝试。请确保 ~/.zshrc 中已启用这些插件。"

        # 切换默认 Shell 到 Zsh
        CURRENT_SHELL=$(basename "$SHELL")
        if [ "$CURRENT_SHELL" != "zsh" ]; then
            echo "正在尝试将默认 Shell 更改为 Zsh..."
            chsh -s zsh
            if [ $? -ne 0 ]; then
                echo "警告: 自动切换默认 Shell 失败。您可能需要手动运行 'chsh -s zsh' 并重启 Termux。"
            else
                echo "默认 Shell 已设置为 Zsh。请重启 Termux 应用以生效。"
            fi
        else
            echo "当前默认 Shell 已是 Zsh。无需切换。"
        fi
    fi
else
    echo "跳过 Zsh 和 Oh My Zsh 配置。"
fi


echo ""
echo "======================================================================"
echo " Termux 开发环境配置完成!"
echo "======================================================================"
echo " 您现在可以在 Termux 终端中输入 'nvim' 来打开 Neovim。"
echo " 推荐的下一步操作:"
echo " 1. 在 Termux 中重启应用，享受 Zsh 美化。"
echo " 2. 在 Neovim 中运行 ':checkhealth' 来验证设置。"
echo " 3. 对于 Python: 创建一个 Python 文件 (.py) 并测试自动补全。"
echo " 4. 对于 C/C++: 创建一个 C/C++ 文件 (.c/.cpp) 并测试自动补全。"
echo " 祝您使用新的 Termux 开发环境愉快!"
echo "======================================================================"