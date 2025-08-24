#!/bin/bash
# update_radicale.sh
# 多用户、多系统、支持 tar.gz / zip 压缩格式
# 日志保存在脚本同目录
# 增强版：中文提示 + 实时输出 + 错误检查

# ---------------- 配置 ----------------
REPO="nrjycyd/radicale-data"           # GitHub 仓库
TAR_NAME="radicale-data.tar.gz"        # tar.gz 文件名
ZIP_NAME="radicale-data.zip"           # zip 文件名
ARCHIVE_TYPE="${ARCHIVE_TYPE:-auto}"   # 指定解压格式: tar.gz | zip | auto（默认 auto）

# 用户与系统映射
declare -A USER_SYSTEM=(
  [admin]="ios"
  [guest]="macos"
  [cn]="ios"
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

# ---------------- 日志函数 ----------------
log() {
    local MSG="$*"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $MSG" | tee -a "$LOG_FILE"
}

log "=============================="
log "开始更新 Radicale 数据"
log "GitHub 仓库 : $REPO"
log "用户列表   : ${!USER_SYSTEM[@]}"
log "解压类型   : $ARCHIVE_TYPE"
log "=============================="

# ---------------- 1. 获取最新 Release 下载链接 ----------------
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
    log "错误: 未找到指定类型的 Release ($ARCHIVE_TYPE)"
    exit 1
fi
log "最新 Release 下载链接: $LATEST_URL"

# ---------------- 2. 下载文件 ----------------
log "开始下载文件: $TMP_FILE ..."
if ! wget --quiet --show-progress --timeout=30 --tries=3 -O "$TMP_FILE" "$LATEST_URL"; then
    log "错误: 下载失败 $TMP_FILE"
    exit 1
fi

if [[ ! -s "$TMP_FILE" ]]; then
    log "错误: 下载文件为空"
    exit 1
fi
log "文件下载完成: $TMP_FILE"

# ---------------- 3. 创建临时目录 ----------------
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

# ---------------- 4. 解压 ----------------
log "开始解压文件: $TMP_FILE ..."
if [[ "$TMP_FILE" == *.tar.gz ]]; then
    tar -zxf "$TMP_FILE" -C "$TMP_DIR" || { log "错误: tar.gz 解压失败"; exit 1; }
elif [[ "$TMP_FILE" == *.zip ]]; then
    unzip -q "$TMP_FILE" -d "$TMP_DIR" || { log "错误: zip 解压失败"; exit 1; }
else
    log "错误: 不支持的压缩格式 $TMP_FILE"
    exit 1
fi
log "解压完成"

# ---------------- 5. 同步用户数据 ----------------
for user in "${!USER_SYSTEM[@]}"; do
    SYSTEM="${USER_SYSTEM[$user]}"
    SRC_DIR="$TMP_DIR/radicale/$SYSTEM"
    if [[ ! -d "$SRC_DIR" ]]; then
        log "警告: 找不到 $SYSTEM 目录, 用户 $user 将被跳过"
        continue
    fi
    USER_DIR="$DEST_DIR/data/collections/collection-root/$user"
    log "更新用户: $user, 系统: $SYSTEM -> $USER_DIR"
    mkdir -p "$USER_DIR"
    rsync -a --delete --ignore-missing-args "$SRC_DIR/" "$USER_DIR/" && log "用户 $user 更新完成"
done

# ---------------- 6. 清理临时文件 ----------------
rm -rf "$TMP_DIR"
rm -f "$TMP_FILE"

log "Radicale 数据更新成功"
log "=============================="
