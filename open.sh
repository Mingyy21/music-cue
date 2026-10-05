#!/bin/bash
# 打开应用窗口（可见），并保持后台存活。
# 直接调 card-host 并传 --size 1280x800 —— 设计主档。octo run 不转发 --size，
# 用默认 412 宽会让 420px 内容列被裁掉。
set -u
export OCTO_CARD_HOST="E:/software2/OctoSense-App-Hub/target/release/card-host.exe"
HUB_REPO="E:/software2/OctoScript-App-Design-Flow"
APP="E:/software2/apps/music-cue"
PORT=8151
SIZE=1280x800
# 演示用独立数据目录：测试套件也在写 .local-state，
# 共用会让测试产生的偏好/快照污染演示状态（实测）。
DATA="$APP/.demo-state"

cd "$HUB_REPO" || exit 1
curl -s "127.0.0.1:$PORT/quit" -m 3 >/dev/null 2>&1
sleep 1

echo "启动 情境音乐任务卡（窗口 ${SIZE}，端口 ${PORT}）…"
MAKEPAD_REMOTE=$PORT "$OCTO_CARD_HOST" \
    --bundle "$APP/bundle" \
    --app-data "$DATA" \
    --allow-unsigned --stamp \
    --size $SIZE >"$APP/.run.log" 2>&1 &
APP_PID=$!

for i in $(seq 1 40); do
    sleep 1
    if curl -s "127.0.0.1:$PORT/snap" -m 2 2>/dev/null | grep -q '"s"'; then
        echo "窗口已打开（第 ${i}s）"; break
    fi
    if ! kill -0 $APP_PID 2>/dev/null; then
        echo "启动失败："; tail -20 "$APP/.run.log"; exit 1
    fi
done

sleep 2
echo; echo "--- 当前界面 ---"
curl -s "127.0.0.1:$PORT/snap" -m 5 2>/dev/null | python -c "
import json,sys
ws=json.load(sys.stdin)['s']
for w in ws:
    t=w.get('t') or ''
    if t and not t.startswith('//'): print('  ', t[:46])
"
echo; echo "--- 运行时错误 ---"
BAD=$(grep -c '\[E\]' "$APP/.run.log" 2>/dev/null || true)
if [ "$BAD" = "0" ] || [ -z "$BAD" ]; then echo "  无"; else grep '\[E\]' "$APP/.run.log" | tail -3; fi

cat <<'EOF'

────────────────────────────────────────────
窗口已打开，可以操作：

  1. 输入框打「晚上想专注」→ 点「生成任务卡」
     （或直接点 专注 / 通勤 / 睡前 / 健身 快捷出卡）
  2. 卡片页可「调整时长」「换一批」「存进卡堆」
  3. 「开始播放」后：跳过 / 收藏（收藏不换曲）/ 结束
     专注场景显示番茄钟轮次
  4. 输入页底部进「卡堆」「我的音乐」「统计」
  5. 右上角「风」按钮切换三套主题

  停止：curl -s 127.0.0.1:8151/quit
────────────────────────────────────────────
EOF
wait $APP_PID
