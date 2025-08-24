#!/bin/bash
# 文件名：update_radicale.sh
# 功能：从 GitHub Release 下载最新的 radicale-data.tar.gz 并更新到 Radicale 数据目录
# 默认用户：cn
# 日志保存在脚本同目录

# ---------------- 配置 ----------------
REPO="nrjycyd/radicale-data"           # GitHub 仓库
TAR_NAME="radicale-data.tar.gz"        # 下载 tar.gz 文件名
RADICALE_USER="${RADICALE_USER:-cn}"  # 默认为 cn
# --------------------------------------

# 脚本目录
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST_DIR="$ROOT_DIR"
CN_DIR="$DEST_DIR/data/collections/collection-root/$RADICALE_USER"
LOG_FILE="$ROOT_DIR/update_radicale.log"

TMP_TAR="$DEST_DIR/$TAR_NAME"
TMP_DIR="$DEST_DIR/tmp_radicale"

# 创建日志头
{
echo "=============================="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Radicale update for user: $RADICALE_USER"
echo "Repository: $REPO"
echo "Target Dir: $CN_DIR"

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

# 3. 检查下载的文件是否有效
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

# 6. 检查 ios 文件夹是否存在
IOS_DIR="$TMP_DIR/radicale/ios"
if [[ ! -d "$IOS_DIR" ]]; then
    echo "Error: ios directory not found in $TAR_NAME"
    rm -rf "$TMP_DIR" "$TMP_TAR"
    exit 1
fi

# 7. 更新 Radicale 数据目录
echo "Updating Radicale data..."
mkdir -p "$CN_DIR"
rsync -a --delete --ignore-missing-args "$IOS_DIR/" "$CN_DIR/"

# 8. 清理临时文件
rm -rf "$TMP_DIR"
rm -f "$TMP_TAR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Radicale data updated successfully for user: $RADICALE_USER"
echo "=============================="

} >> "$LOG_FILE" 2>&1
