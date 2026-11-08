# CodeBuddy 子镜像：底座负责 ACP 转发、首启下载、登录网页；这里只放 agent.toml、网关钩子、
# ACP 启动壳和登录脚本。CLI 是 MIT 许可但闭源，按底座约定首次启动从 npm 官方源按摘要下载。
ARG BASE_IMAGE=ghcr.io/geraldpeng6/wonton-agent-base:0.1.0@sha256:9d6e0ca87c14eee21b5b6503fb52dd863182e7a4f784dd644a4e8cb3f58989d7
FROM ${BASE_IMAGE}

COPY agent.toml /etc/wonton-agent/
COPY --chmod=0755 codebuddy-acp codebuddy-acp-client codebuddy-key-login codebuddy-gateway \
     /usr/local/lib/wonton-agent/
COPY skills/ /usr/local/share/wonton-agent/skills/
COPY prompt.md /usr/local/share/wonton-agent/prompt.md
COPY LICENSE.codebuddy /usr/share/doc/wonton-plugin-codebuddy/LICENSE.codebuddy

# 遥测、错误上报和自更新：版本由 [[install]] 固定，CLI 自己不再升级。
ENV DISABLE_TELEMETRY=1 \
    DISABLE_ERROR_REPORTING=1 \
    DISABLE_AUTOUPDATER=1
