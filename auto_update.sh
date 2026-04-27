#!/bin/bash

# ========================================================
# 1. 时间段自定义 (24小时制)
# ========================================================
# 早高峰：07:00 - 09:59
MORNING_PEAK_START=8
MORNING_PEAK_END=10

# 晚高峰：18:00 - 23:59 (包含 0点)
EVENING_PEAK_START=18
EVENING_PEAK_END=23
MIDNIGHT=0

# ========================================================
# 2. 目标 IP 及权重配置 (关联数组)
# 格式: ["IP地址"]="早高峰权重,晚高峰权重,常规权重"
# ========================================================
declare -A CONFIG
CONFIG=(
    # IP地址  早, 晚, 常规
    ["ip1"]="80,100,0"
    ["ip2"]="100,50,100"
    ["ip3"]="80,100,50"
)

# ========================================================
# 3. 核心逻辑
# ========================================================
SCRIPT_PATH="/etc/haproxy/update_weight.sh"
current_hour=$(date +%H)
current_hour=$((10#$current_hour))

# 判断当前属于哪个时段索引 (1:早, 2:晚, 3:常规)
if [[ "$current_hour" -ge "$MORNING_PEAK_START" && "$current_hour" -le "$MORNING_PEAK_END" ]]; then
    PERIOD_INDEX=1
    PERIOD_NAME="早高峰"
elif [[ "$current_hour" -ge "$EVENING_PEAK_START" && "$current_hour" -le "$EVENING_PEAK_END" ]] || [[ "$current_hour" -eq "$MIDNIGHT" ]]; then
    PERIOD_INDEX=2
    PERIOD_NAME="晚高峰"
else
    PERIOD_INDEX=3
    PERIOD_NAME="常规时段"
fi

echo "$(date): --- 当前进入 $PERIOD_NAME ($current_hour:00) ---"

# 遍历配置
for ip in "${!CONFIG[@]}"; do
    WEIGHT_LIST=${CONFIG[$ip]}
    
    # 根据索引提取权重
    FINAL_WEIGHT=$(echo $WEIGHT_LIST | cut -d',' -f$PERIOD_INDEX)
    
    echo "更新 $ip: 权重设为 $FINAL_WEIGHT"
    $SCRIPT_PATH "$ip" "$FINAL_WEIGHT"
done
