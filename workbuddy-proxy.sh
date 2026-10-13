#!/usr/bin/env bash
# workbuddy-proxy - 管理本地 WorkBuddy OpenAI/Anthropic 兼容反代
#
# workbuddy-proxy.cmd 的 Linux / macOS（bash）版本，委派给子模块 refs/workbuddy-openai-proxy。
# 上游零依赖，直接 `node server.mjs` 即可，不需要 npm install。
# 本文件必须保持 LF 行尾（见 .gitattributes）：CRLF 会破坏 shebang。
set -euo pipefail

# 解析脚本自身所在目录；跟随软链，兼容从任意 cwd 调用
self="${BASH_SOURCE[0]}"
while [ -L "$self" ]; do
	target="$(readlink "$self")"
	case "$target" in
		/*) self="$target" ;;
		*) self="$(dirname "$self")/$target" ;;
	esac
done
here="$(cd "$(dirname "$self")" && pwd)"
proxy_dir="$here/refs/workbuddy-openai-proxy"
log_file="$proxy_dir/server.log"

if [ ! -f "$proxy_dir/server.mjs" ]; then
	echo "workbuddy-proxy: 找不到子模块：$proxy_dir" >&2
	echo "workbuddy-proxy: 请先拉取：" >&2
	echo "  git submodule update --init refs/workbuddy-openai-proxy" >&2
	exit 1
fi

if ! command -v node >/dev/null 2>&1; then
	echo "workbuddy-proxy: PATH 里没有 node（需要 Node 18+）" >&2
	exit 1
fi

cd "$proxy_dir"

# 端口以子模块的 config.json 为准（loadConfig 默认 host=127.0.0.1 / port=8788）
base_url="$(
	node -e 'import("./src/config.mjs").then(({ loadConfig }) => { const c = loadConfig(); console.log("http://" + c.host + ":" + c.port); }).catch(() => process.exit(1))' 2>/dev/null
)" || base_url=""
if [ -z "$base_url" ]; then
	base_url="http://127.0.0.1:8788"
fi

# 探活：借 node 自带的 fetch，避免依赖 curl
probe() {
	node -e 'fetch(process.argv[1], { signal: AbortSignal.timeout(2000) }).then((r) => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))' \
		"$base_url/health" >/dev/null 2>&1
}

# 等服务就绪：最多 ${1:-15} 秒
wait_ready() {
	local deadline=$((SECONDS + ${1:-15}))
	while [ "$SECONDS" -lt "$deadline" ]; do
		if probe; then return 0; fi
		sleep 0.5
	done
	return 1
}

# 等端口释放（stop 是优雅退出，需要一点时间）
wait_down() {
	local deadline=$((SECONDS + ${1:-10}))
	while [ "$SECONDS" -lt "$deadline" ]; do
		if ! probe; then return 0; fi
		sleep 0.5
	done
	return 1
}

# 后台常驻：与 start-hidden.vbs 等价（nohup + 追加写 server.log，关终端不掉）
spawn_background() {
	nohup node server.mjs >>"$log_file" 2>&1 &
	disown 2>/dev/null || true
}

do_start() {
	echo "正在后台启动 WorkBuddy 反代：$base_url ..."
	echo "控制台：$base_url/console   （首次使用先跑：workbuddy-proxy.sh login）"
	echo "日志：$log_file"
	spawn_background
	if wait_ready 15; then
		echo "已就绪。"
	else
		echo "workbuddy-proxy: 15 秒内未就绪，请查看日志：$log_file" >&2
		exit 1
	fi
}

do_stop() {
	# 走上游的管理接口优雅退出（不依赖进程枚举）
	node stop.mjs
}

do_login() {
	node login.mjs "$@"
}

do_status() {
	node status.mjs "$@"
}

do_console() {
	local url="$base_url/console"
	if ! probe; then
		echo "服务未在运行，正在后台启动…"
		spawn_background
		if ! wait_ready 20; then
			echo "workbuddy-proxy: 启动超时，请查看日志：$log_file" >&2
			exit 1
		fi
		echo "服务已就绪。"
	fi
	# console-open.mjs 只认 Windows 下的 Edge/Chrome 路径，Linux 用 xdg-open
	if [ "$(uname -s)" = "Darwin" ] && command -v open >/dev/null 2>&1; then
		nohup open "$url" >/dev/null 2>&1 &
		disown 2>/dev/null || true
		echo "已打开控制台：$url"
	elif command -v xdg-open >/dev/null 2>&1; then
		nohup xdg-open "$url" >/dev/null 2>&1 &
		disown 2>/dev/null || true
		echo "已打开控制台：$url"
	else
		echo "无图形环境（找不到 xdg-open / open），请手动打开：$url"
	fi
}

do_ask() {
	if [ "$#" -eq 0 ]; then
		# 服务没在跑时 --list 会失败，但用法仍要打出来
		node ask.mjs --list || true
		echo
		echo "用法：workbuddy-proxy.sh ask <model-id> \"你的问题\""
		echo "  例：workbuddy-proxy.sh ask claude-sonnet-4.6 \"hello\""
		echo "      workbuddy-proxy.sh ask gpt-5.4 \"写一个快排\""
	else
		node ask.mjs "$@"
	fi
}

action="${1:-start}"
if [ "$#" -gt 0 ]; then shift; fi

case "$action" in
	start) do_start ;;
	stop) do_stop ;;
	restart)
		do_stop
		wait_down 10 || true
		do_start
		;;
	login) do_login "$@" ;;
	status) do_status "$@" ;;
	console) do_console ;;
	ask) do_ask "$@" ;;
	*)
		echo "用法：workbuddy-proxy.sh [start | stop | restart | login | status | console | ask]" >&2
		exit 1
		;;
esac
