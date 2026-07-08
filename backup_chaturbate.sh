#!/bin/bash

# ==============================================================================
# Script Name: backup_chaturbate.sh
# Description: Automate backup of ffmpeg completed recordings (>5 mins modified)
#              using rclone to 115 remote, with staging and cleanup steps.
# ==============================================================================

# 配置变量 (Configuration Variables)
SRC_DIR="/srv/data/ffmpeg"
BACKUP_DIR="/srv/data/backup"
RCLONE_REMOTE="DaiYufan08"
RCLONE_DEST_DIR="/Sofia/ffmpeg"
# 自动生成备份日期文件夹名称，格式为 YYYY-MM-DD (e.g. 2026-07-08)
DATE_FOLDER=$(date +%Y-%m-%d)
# 今日备份存放的子文件夹
TODAY_BACKUP_DIR="${BACKUP_DIR}/${DATE_FOLDER}"
# rclone 备份的目标路径 (今日备份文件夹对应的远程路径)
DEST_PATH="${RCLONE_REMOTE}:${RCLONE_DEST_DIR}/${DATE_FOLDER}"

# 确保备份临时文件夹存在
mkdir -p "$BACKUP_DIR"

# 写入日志的辅助函数（直接输出到标准输出，供脚本外部统一重定向）
log_message() {
    local message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $message"
}

log_message "==================== 开始备份流程 ===================="

# 第一步：删除修改时间超过 5 分钟且文件大小小于 500M 的文件
log_message "步骤 1: 正在删除 ${SRC_DIR} 中修改时间超过 5 分钟且小于 500M 的无效文件..."
DEL_COUNT=$(find "$SRC_DIR" -maxdepth 1 -type f -mmin +5 -size -500M | wc -l)
if [ "$DEL_COUNT" -gt 0 ]; then
    find "$SRC_DIR" -maxdepth 1 -type f -mmin +5 -size -500M -delete
    log_message "已成功删除 $DEL_COUNT 个小于 500M 的文件。"
else
    log_message "没有发现需要删除的无效文件。"
fi

# 第二步：查找修改时间超过5分钟的文件，并在备份文件夹下新建今日日期命名的子文件夹存放
log_message "步骤 2: 正在查找并移动 ${SRC_DIR} 中修改时间超过 5 分钟的文件到今日备份文件夹 ${TODAY_BACKUP_DIR}..."

# 获取待处理的文件数量（包括源目录中符合条件的，以及今日暂存目录中的文件）
SRC_COUNT=$(find "$SRC_DIR" -maxdepth 1 -type f -mmin +5 | wc -l)
if [ -d "$TODAY_BACKUP_DIR" ]; then
    BACKUP_COUNT=$(find "$TODAY_BACKUP_DIR" -type f | wc -l)
else
    BACKUP_COUNT=0
fi
TOTAL_COUNT=$((SRC_COUNT + BACKUP_COUNT))

if [ "$TOTAL_COUNT" -eq 0 ]; then
    log_message "没有找到需要备份的文件。备份结束。"
    log_message "==================== 备份流程结束 (无文件) ===================="
    exit 0
fi

# 移动文件到今日备份日期文件夹中（如果源目录有符合条件的文件）
if [ "$SRC_COUNT" -gt 0 ]; then
    mkdir -p "$TODAY_BACKUP_DIR"
    find "$SRC_DIR" -maxdepth 1 -type f -mmin +5 -exec mv -t "$TODAY_BACKUP_DIR" {} +
    log_message "成功移动了 $SRC_COUNT 个文件到 ${TODAY_BACKUP_DIR}。"
fi
log_message "当前暂存区 ${TODAY_BACKUP_DIR} 中共有 $TOTAL_COUNT 个文件等待备份。"

# 第三步：启动 rclone 备份程序并重定向输出到日志
log_message "步骤 3: 启动 rclone copy 备份到 ${DEST_PATH}..."

# 执行 rclone copy 命令
rclone copy "$TODAY_BACKUP_DIR" "$DEST_PATH" --multi-thread-streams 0 --transfers 4 -P
RCLONE_EXIT_CODE=$?

# 第四步：完成备份后删除本次备份的源文件（今日暂存文件夹）
if [ $RCLONE_EXIT_CODE -eq 0 ]; then
    log_message "rclone 备份成功！"
    log_message "步骤 4: 正在删除本次备份的源文件 ${TODAY_BACKUP_DIR}..."
    rm -rf "$TODAY_BACKUP_DIR"
    log_message "源文件已成功清理。"
    log_message "==================== 备份流程成功结束 ===================="
else
    log_message "错误: rclone 备份失败，退出代码为: ${RCLONE_EXIT_CODE}！"
    log_message "今日暂存文件夹 ${TODAY_BACKUP_DIR} 中的文件依然保留，请检查原因。"
    log_message "==================== 备份流程异常结束 ===================="
    exit 1
fi
