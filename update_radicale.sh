#!/bin/bash
# 文件名：update_radicale.sh
# 默认用户 admin
# 日志保存到脚本所在目录

# ---------------- 配置 ----------------
REPO="nrjycyd/radicale-data"           # GitHub 仓库，例如 nrjycyd/radicale-data
TAR_NAME="radicale-data.tar.gz"        # 下载 tar.gz 文件
RADICALE_USER="${RADICALE_USER:-admin}"  # 默认为 admin
# --------------------------------------

# 脚本所在目录作为根目录
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST_DIR="$ROOT_DIR"
CN_DIR="$DEST_DIR/data/collections/collection-root/$RADICALE_USER"
LOG_FILE="$ROOT_DIR/update_radicale.log"

TMP_TAR="$DEST_DIR/$TAR_NAME"
TMP_DIR="$DEST_DIR/tmp_radicale"

{
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Radicale update for user: $RADICALE_USER"

# 1. 下载最新 Release
echo "Downloading latest Radicale data..."
LATEST_URL=$(curl -s https://api.github.com/repos/$REPO/releases/latest \
  | grep browser_download_url \
  | grep "$TAR_NAME" \
  | cut -d '"' -f 4)

if [ -z "$LATEST_URL" ]; then
    echo "Error: Cannot find latest release URL for $TAR_NAME"
    exit 1
fi

wget -O "$TMP_TAR" "$LATEST_URL"

if [ ! -f "$TMP_TAR" ]; then
    echo "Error: failed to download $TAR_NAME"
    exit 1
fi

# 2. 创建临时目录
mkdir -p "$TMP_DIR"

# 3. 解压 tar.gz
echo "Extracting $TAR_NAME..."
tar -zxvf "$TMP_TAR" -C "$TMP_DIR"

# 4. 检查 ios 文件夹是否存在
IOS_DIR="$TMP_DIR/radicale/ios"
if [ ! -d "$IOS_DIR" ]; then
    echo "Error: ios directory not found in the tar!"
    exit 1
fi

# 5. 复制 ios 下的所有内容到 CN_DIR
mkdir -p "$CN_DIR"
rsync -av --progress --delete "$IOS_DIR/" "$CN_DIR/"

# 6. 清理临时文件
rm -rf "$TMP_DIR"
rm -f "$TMP_TAR"

echo "Radicale data updated successfully for user: $RADICALE_USER"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Update finished"

} >> "$LOG_FILE" 2>&1
