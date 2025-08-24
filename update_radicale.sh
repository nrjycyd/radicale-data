#!/bin/bash
# 文件名：update_radicale.sh
# 功能：从 GitHub Release 下载最新 radicale-data.tar.gz，支持多用户同步，支持 ios/macos 平台
# 日志保存在脚本同目录

# ---------------- 配置 ----------------
REPO="nrjycyd/radicale-data"           # GitHub 仓库
TAR_NAME="radicale-data.tar.gz"        # 下载 tar.gz 文件名
USERS=("cn" "alice" "bob")             # 需要同步的 Radicale 用户
SYSTEM="${SYSTEM:-ios}"               # 系统类型：ios | macos，默认 ios
# --------------------------------------

# 脚本目录
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST_DIR="$ROOT_DIR"
LOG_FILE="$ROOT_DIR/update_radicale.log"

TMP_TAR="$DEST_DIR/$TAR_NAME"
TMP_DIR="$DEST_DIR/tmp_radicale"

# 写入日志头
{
echo "=============================="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Radicale update"
echo "Repository : $REPO"
echo "Users      : ${USERS[*]}"
echo "System     : $SYSTEM"
echo "=============================="

# 1. 获取最新 Release 下载链接
echo "Fetching latest release URL..."
LATEST_URL=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | \
    grep "browser_download_url" | grep "$TAR_NAME" | cut -d '"' -f 4)

if [[ -z "$LATEST_URL" ]]; then
    echo "Error: Cannot find latest release URL for $TAR_NAME"
    exit 1
fi
echo "Found latest release: $LATEST_URL"

# 2. 下载最新 Release
echo "Downloading $TAR_NAME..."
if ! wget --quiet --show-progress --timeout=30 --tries=3 -O "$TMP_TAR" "$LATEST_URL"; then
    echo "Error: Failed to download $TAR_NAME"
    exit 1
fi

# 3. 检查下载文件是否有效
if [[ ! -s "$TMP_TAR" ]]; then
    echo "Error: Downloaded file is empty"
    exit 1
fi

# 4. 创建临时目录
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

# 5. 解压 tar.gz
echo "Extracting $TAR_NAME..."
if ! tar -zxf "$TMP_TAR" -C "$TMP_DIR"; then
    echo "Error: Failed to extract $TAR_NAME"
    rm -f "$TMP_TAR"
    exit 1
fi

# 6. 检查对应系统文件夹是否存在
SRC_DIR="$TMP_DIR/radicale/$SYSTEM"
if [[ ! -d "$SRC_DIR" ]]; then
    echo "Error: $SYSTEM directory not found in $TAR_NAME"
    rm -rf "$TMP_DIR" "$TMP_TAR"
    exit 1
fi
echo "Using source directory: $SRC_DIR"

# 7. 为每个用户同步数据
for user in "${USERS[@]}"; do
    USER_DIR="$DEST_DIR/data/collections/collection-root/$user"
    echo "Updating data for user: $user -> $USER_DIR"
    mkdir -p "$USER_DIR"
    rsync -a --delete --ignore-missing-args "$SRC_DIR/" "$USER_DIR/"
done

# 8. 清理临时文件
rm -rf "$TMP_DIR"
rm -f "$TMP_TAR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Radicale data updated successfully"
echo "=============================="

} >> "$LOG_FILE" 2>&1
