# 抖音团购选品图文/视频发布自动化

抖音本地生活团购内容自动发布技能包：从生意经选品，到生成公开推广内容，再到抖音图文或视频发布并挂团购位置。

![抖音团购选品图文发布自动化流程](assets/workflow.svg)

## 这个技能是干嘛的

把原来需要人工反复操作的链路串起来：

1. 去抖音来客/生意经看昨天卖得好的卡券。
2. 回到来客商品管理查商品详情。
3. 生成对外推广用的标题、正文和海报 prompt。
4. 用 Codex 原生生图生成 3-5 张图文海报。
5. 自动上传抖音图文或视频，并挂正确的国内团购位置；图文可同时选择推荐音乐。

## 能力清单

| 模块 | 是否 CLI/Python 化 | 入口 | 说明 |
| --- | --- | --- | --- |
| 登录检查 | 是 | `./bin/sau douyin check` | 检查抖音账号 cookie 是否有效 |
| 选品 | 是 | `douyin_groupbuy_pipeline.py select` | 进抖音来客/生意经，按昨日成交券数等指标取商品 |
| 商品详情读取 | 是 | `sau douyin select-groupbuy-products` | 通过商品 ID 回到来客商品管理读取详情 |
| 公开 brief | 是 | `douyin_groupbuy_pipeline.py brief` | 生成标题、正文、图片 prompt 和发布元数据 |
| 原生生图 | Codex skill 化 | `image_prompts.md` + `imagegen` | 用 ChatGPT/Codex 原生生图生成 3-5 张海报 |
| 图文发布 | 是 | `douyin_groupbuy_pipeline.py publish` | 上传图片、选音乐、挂国内 POI、发布 |
| 视频发布 | 是 | `./bin/douyin-groupbuy publish-video` | 上传单条视频、挂带货模式国内 POI、发布 |
| 团购位置 | 是 | runtime patch | 强制 `位置 -> 带货模式 -> 国内 -> 输入 POI -> 选匹配候选` |
| 单浏览器发布 | 是 | runtime patch | 发布时不再另开 3 次 cookie 预检窗口，上传和登录校验共用一个 Chrome 会话 |

![命令和产物关系](assets/usage-map.svg)

## 安装

```bash
git clone https://github.com/784697524-ux/douyin-groupbuy-auto-publish.git
cd douyin-groupbuy-auto-publish
./install.sh
./scripts/apply_douyin_groupbuy_patch.sh
```

默认依赖本机 runtime：

```text
$HOME/.openclaw/workspace/social-auto-upload
```

如 runtime 在其他目录：

```bash
export SOCIAL_AUTO_UPLOAD_HOME="/path/to/social-auto-upload"
```

## 快速使用

需要单独确认账号状态时再检查登录；正常发布可直接运行发布命令：

```bash
./bin/sau douyin check --account likai_douyin_2
```

选取昨日成交券数靠前的卡券：

```bash
python scripts/douyin_groupbuy_pipeline.py select \
  --account likai_douyin_2 \
  --groupid 1748531528342532 \
  --date "昨天" \
  --metric "商品成交券数" \
  --limit 3 \
  --output /Users/likai/Desktop/AI/图文团购/outputs/selection.json \
  --headed
```

生成公开推广工作包：

```bash
python scripts/douyin_groupbuy_pipeline.py brief \
  --selection /Users/likai/Desktop/AI/图文团购/outputs/selection.json \
  --product-index 1 \
  --output-dir /Users/likai/Desktop/AI/图文团购/outputs/groupbuy_work \
  --location "合肥滨湖银泰百货"
```

用 Codex 原生生图读取：

```text
/Users/likai/Desktop/AI/图文团购/outputs/groupbuy_work/image_prompts.md
```

生成 3-5 张图片，并放到：

```text
/Users/likai/Desktop/AI/图文团购/outputs/groupbuy_work/images/
```

发布图文：

```bash
python scripts/douyin_groupbuy_pipeline.py publish \
  --account likai_douyin_2 \
  --work-dir /Users/likai/Desktop/AI/图文团购/outputs/groupbuy_work \
  --location "合肥滨湖银泰百货" \
  --bgm auto \
  --headed
```

发布视频并挂团购位置：

```bash
./bin/douyin-groupbuy publish-video \
  --account likai_douyin_2 \
  --file /path/to/video.mp4 \
  --title "猛男被叫美女后，真香买了19.9逛吃卡" \
  --desc "中大银泰服务台短剧，19.9逛吃卡真香反转。" \
  --tags "杭州中大银泰,19块9逛吃卡,杭州团购,本地生活" \
  --location "杭州中大银泰百货" \
  --headed
```

该命令复用已验证成功的视频发布链路：`位置 -> 带货模式/视频位置入口 -> 国内 -> 输入门店 -> 等待候选 -> 选择匹配项 -> 发布`。

发布命令只启动一个 Chrome 会话。它会在这个会话里同时检查登录状态并完成上传；cookie 失效时会提示先执行 `douyin login`，不会再连续打开 4-5 个窗口。

位置选择会走下面这条固定链路，避免选成店铺级 POI：

![团购位置选择示意](assets/poi-location.svg)

## 成功标准

- 选品：输出 `selection.json`，且包含商品名、商品 ID、公开文案所需商品信息。
- 生成：工作目录包含 `title.txt`、`caption.txt`、`image_prompts.md`、`publish_meta.json`、`images/`。
- 发布：CLI 返回发布成功，并进入作品管理页或平台成功状态；日志必须出现已选择的目标门店。

如果出现短信验证码、验证码、位置候选错误，不能算发布完成。

## 隐私边界

仓库不包含：

- 抖音 cookie
- 二维码
- 浏览器 profile
- 发布日志
- 账号密码
- 商品后台成交数据截图

公开文案和海报不要展示商品 ID、后台售卖张数、成交金额、内部排名。
