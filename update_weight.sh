#!/bin/bash
SOCK="/var/run/haproxy/admin.sock"

TARGET="$1"      # 要匹配的 server 名或 IP
NEW_WEIGHT="$2"   # 目标权重

if [ -z "$TARGET" ] || [ -z "$NEW_WEIGHT" ]; then
    echo "用法: $0 <server名或IP> <weight>"
    exit 1
fi

echo "调整所有 active 节点中匹配 '$TARGET' 的权重为 $NEW_WEIGHT"

# 获取所有后端 server 状态
# 字段：be_id be_name srv_id srv_name srv_addr srv_op_state ...
mapfile -t SERVERS < <(echo "show servers state" | socat stdio $SOCK | tail -n +2)

for line in "${SERVERS[@]}"; do
    backend=$(echo $line | awk '{print $2}')
    server=$(echo $line | awk '{print $4}')
    addr=$(echo $line | awk '{print $5}')
    status=$(echo $line | awk '{print $6}')
    weight=$(echo $line | awk '{print $8}')  # srv_uweight

    # 只处理 active 节点 (状态=2 UP)
    if [[ "$status" == "2" ]] && ([[ "$addr" == "$TARGET" ]] || [[ "$server" == "$TARGET" ]]); then
        echo "调整 $backend/$server ($addr) 权重 $weight → $NEW_WEIGHT"
        echo "set server $backend/$server weight $NEW_WEIGHT" | socat stdio $SOCK
    fi
done

# 验证修改
echo "===== 当前匹配 '$TARGET' 的节点权重 ====="
echo "show servers state" | socat stdio $SOCK | awk -v tgt="$TARGET" '$4==tgt || $5==tgt {print $2, $4, $5, $8, $6}'
