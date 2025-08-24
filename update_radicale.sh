#!/bin/bash
# update_radicale.sh
# 多用户、多系统、支持 tar.gz / zip 压缩格式
# 日志保存在脚本同目录

# ---------------- 配置 ----------------
REPO="nrjycyd/radicale-data"           # GitHub 仓库
TAR_NAME="radicale-data.tar.gz"        # tar.gz 文件名
ZIP_NAME="radicale-data.zip"           # zip 文件名
ARCHIVE_TYPE="${ARCHIVE_TYPE:-auto}"   # 指定解压格式: tar.gz | zip | auto（默认 auto）

# 用户与系统映射
declare -A USER_SYSTEM=(
  [cn]="ios"
  [alice]="macos"
  [bob]="ios"
)

# UTF-8 环境，防止 zip 中文乱码
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 路径设置
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST_DIR="$ROOT_DIR"
LOG_FILE="$ROOT_DIR/update_radicale.log"

TMP_FILE="$DEST_DIR/tmp_radicale_archive"
TMP_DIR="$DEST_DIR/tmp_radicale"

# 写入日志头
{
echo "=============================="
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Radicale update"
echo "Repository : $REPO"
echo "Users      : ${!USER_SYSTEM[@]}"
echo "Archive    : $ARCHIVE_TYPE"
echo "=============================="

# 1. 获取最新 Release 下载链接
RELEASE_JSON=$(curl -s "https://api.github.com/repos/$REPO/releases/latest")

if [[ "$ARCHIVE_TYPE" == "tar.gz" ]]; then
    LATEST_URL=$(echo "$RELEASE_JSON" | grep "browser_download_url" | grep "$TAR_NAME" | cut -d '"' -f 4)
    TMP_FILE="$DEST_DIR/$TAR_NAME"
elif [[ "$ARCHIVE_TYPE" == "zip" ]]; then
    LATEST_URL=$(echo "$RELEASE_JSON" | grep "browser_download_url" | grep "$ZIP_NAME" | cut -d '"' -f 4)
    TMP_FILE="$DEST_DIR/$ZIP_NAME"
else
    # auto: 优先 tar.gz，其次 zip
    LATEST_URL=$(echo "$RELEASE_JSON" | grep "browser_download_url" | grep "$TAR_NAME" | cut -d '"' -f 4)
    TMP_FILE="$DEST_DIR/$TAR_NAME"
    if [[ -z "$LATEST_URL" ]]; then
        LATEST_URL=$(echo "$RELEASE_JSON" | grep "browser_download_url" | grep "$ZIP_NAME" | cut -d '"' -f 4)
        TMP_FILE="$DEST_DIR/$ZIP_NAME"
    fi
fi

if [[ -z "$LATEST_URL" ]]; then
    echo "Error: No release found for requested archive type: $ARCHIVE_TYPE"
    exit 1
fi

echo "Downloading archive: $TMP_FILE from $LATEST_URL..."
if ! wget --quiet --show-progress --timeout=30 --tries=3 -O "$TMP_FILE" "$LATEST_URL"; then
    echo "Error: Failed to download $TMP_FILE"
    exit 1
fi

# 2. 检查文件有效性
if [[ ! -s "$TMP_FILE" ]]; then
    echo "Error: Downloaded file is empty"
    exit 1
fi

# 3. 创建临时目录
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

# 4. 解压
echo "Extracting $TMP_FILE..."
EXT="${TMP_FILE##*.}"
if [[ "$TMP_FILE" == *.tar.gz ]]; then
    tar -zxf "$TMP_FILE" -C "$TMP_DIR"
elif [[ "$TMP_FILE" == *.zip ]]; then
    unzip -q "$TMP_FILE" -d "$TMP_DIR"
else
    echo "Error: Unsupported archive format for $TMP_FILE"
    exit 1
fi

# 5. 为每个用户同步对应系统数据
for user in "${!USER_SYSTEM[@]}"; do
    SYSTEM="${USER_SYSTEM[$user]}"
    SRC_DIR="$TMP_DIR/radicale/$SYSTEM"
    if [[ ! -d "$SRC_DIR" ]]; then
        echo "Warning: $SYSTEM directory not found for user $user, skipping..."
        continue
    fi
    USER_DIR="$DEST_DIR/data/collections/collection-root/$user"
    echo "Updating user: $user, system: $SYSTEM -> $USER_DIR"
    mkdir -p "$USER_DIR"
    rsync -a --delete --ignore-missing-args "$SRC_DIR/" "$USER_DIR/"
done

# 6. 清理临时文件
rm -rf "$TMP_DIR"
rm -f "$TMP_FILE"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Radicale data updated successfully"
echo "=============================="

} >> "$LOG_FILE" 2>&1
