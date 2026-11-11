# CodeBuddy

开发流程见[插件开发指南](https://github.com/wontonapp/wonton-docs/blob/main/develop.md)。

CodeBuddy 是住在云吞里的 Agent：腾讯的 CodeBuddy Code（官方 `--acp` 接口）用核心分配的 Matrix 身份和主人聊天，
经 Wonton MCP 总线调用工具。模型网关接好时默认走网关，不用账号、也不用填 key；没接网关时 Agent 照常启动，
在 App 的插件页打开登录网页（默认 Bot），或在聊天里发 `/wonton login`（这个聊天对应的 Bot）登录 ——
微信账号、Google / GitHub 账号，或贴一个自己的 API key。

登录态和 key 都在插件数据目录里，容器重建后还在；网关接入或卸掉后重启容器即切换，网关只覆盖模型请求那一层，
账号凭据和用户自己的 key 不动。

## 构建镜像

```bash
docker build -t ghcr.io/geraldpeng6/wonton-plugin-codebuddy:0.1.0 -f images/wonton-plugin-codebuddy/Dockerfile images/wonton-plugin-codebuddy
```

构建出来的是本地 Agent 镜像，`docker image inspect -f '{{.Id}}'` 就是要写回 compose 的摘要。
桥镜像由主仓库维护，`scripts/publish.sh` 只构建本仓库 `images/` 下的 Agent 镜像。

## 登录

第一次用先在插件页的登录网页（默认 Bot）或聊天里发 `/wonton login`（这个聊天对应的 Bot），三选一：

- **微信账号**（国内站）：点登录后把链接在任意浏览器打开，微信扫码。
- **Google / GitHub 账号**（国际站）：同样的链接流程，用 Google 或 GitHub 登录。
- **API key**：从 CodeBuddy 控制台复制 key 贴进输入框，发空行可以清除。

登录成功后容器自己重启，之后正常对话。没接网关时也可以只填 API key，不必登账号。

## 图标

`icon.svg` 是按插件规范手绘的线条图标（对话气泡），原创，随插件包以 MIT 许可证分发。CodeBuddy、腾讯云是腾讯的商标；
本插件不是官方出品。来源、上游程序和许可证的说明见 [NOTICE](NOTICE)。
