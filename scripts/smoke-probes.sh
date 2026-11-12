# CodeBuddy 是 Agent：网页是登录页（底座的静态页，sso: none，网关挡在前面），没有应用账号体系或插件自己的 MCP 服务。
# shellcheck shell=bash disable=SC2034
# 通用插件冒烟验证装得上、登录页打得开、工作区文件升级和重装不丢；加密 Matrix 私聊、模型回答、Wonton MCP 工具、
# 确认卡片、打断、重启、登录和名单外不应答在附加检查里实测（套件的 Agent 助手，见 scripts/agent-probes.sh）。
IDENTITY_NA=1
SMOKE_NOTE="CodeBuddy 的网页是登录页，没有应用账号体系，用户身份由核心网关保证；没有自己的 MCP 服务。"

# CodeBuddy 首次回答要先在容器里装 CLI，十几分钟才回；调 MCP 工具、跑命令都会先弹卡片，一个动作可能弹几张。
EXTRA_TIMEOUT=7200
AGENT_WAIT=860
# 卡片窗口按“Bot 安静”计时：CLI 在后台干活时能十几分钟没有一条消息（这轮实测 `touch` 的卡片 15 分钟后才来、
# 期间只有一句“在想”），480 秒不够；安静 1200 秒才放弃，绝对上限用套件默认的 1800 秒。
AGENT_CARD_WAIT=1200
AGENT_HEALTHY_WAIT=360

# CodeBuddy 收到提示先回一句状态（在想、在写回复、在忙别的）就把这轮结束，真正干活在后台，回答晚几分钟才到。
# 套件的探针在要卡片的用例前自己等上一轮结束：核心记的模型请求/工具调用/卡片都清零、安静 AGENT_IDLE_QUIET 秒
# 才发下一条提示（最长 AGENT_IDLE_WAIT 秒）。它的两条状态能隔几分钟，安静门限放宽到 60 秒。
AGENT_IDLE_QUIET=60
AGENT_IDLE_WAIT=900

extra_check() {
  agent_check_chat '请用一句话回答：codebuddy 冒烟。记住暗号：青杏。'
  agent_check_model
  agent_check_mcp_chat card
  agent_check_mcp_bus
  agent_check_card agent
  agent_check_interrupt
  agent_check_restart agent bridge
  agent_check_resume 青杏
  agent_check_outsider
  agent_check_login_web internal external api-key
  agent_check_login internal,external,api-key 'https://[^ ]+/login\?'
  agent_check_login api-key 'API key'
}

web_assert() { grep -q '<title>登录</title>'; }

# 数据：Agent 的工作区（${WONTON_BOT_DATA}/workspace）会话之间一直在用。data_write 在 agent 容器的工作区落一个
# 带随机令牌的标记文件，data_check 在升级、重装后读回比对。
_cb_container() { running_container "wonton-${SMOKE_INSTANCE:-}--${SMOKE_SLUG:-}--agent"; }

data_write() {
  local container token out
  container="$(_cb_container)" || { echo "找不到 agent 容器"; return 1; }
  token="wonton-smoke-$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
  docker exec "$container" sh -c "printf 'wonton-smoke %s\n' '$token' > /workspace/wonton-smoke-marker" ||
    { echo "往 $container:/workspace 写标记失败"; return 1; }
  out="$(docker exec "$container" cat /workspace/wonton-smoke-marker)" || { echo "标记写完读不回"; return 1; }
  grep -qF "$token" <<<"$out" || { echo "标记读回对不上：$out"; return 1; }
  printf '%s' "$token" >"$SMOKE_STATE" || { echo "写不进标记文件"; return 1; }
}

data_check() {
  local container token out
  container="$(_cb_container)" || { echo "找不到 agent 容器"; return 1; }
  token="$(cat "$SMOKE_STATE" 2>/dev/null)" || true
  [[ -n "$token" ]] || { echo "没有 data_write 留下的标记"; return 1; }
  out="$(docker exec "$container" cat /workspace/wonton-smoke-marker 2>/dev/null)" ||
    { echo "标记文件没了：$container:/workspace/wonton-smoke-marker 读不回"; return 1; }
  grep -qF "$token" <<<"$out" || { echo "标记内容对不上：$(head -c 120 <<<"$out")"; return 1; }
  echo "工作区里的标记还在（wonton-smoke $token）"
}
