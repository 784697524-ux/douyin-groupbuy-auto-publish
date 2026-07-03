# 使用说明

## 1. 应用 runtime patch

```bash
./scripts/apply_douyin_groupbuy_patch.sh
```

它会给本机 `social-auto-upload` runtime 增加：

- `sau douyin select-groupbuy-products`
- `sau douyin upload-note --location --bgm`
- `sau douyin upload-video --location`
- 抖音发布页国内 POI 选择逻辑

## 2. 选品

```bash
python scripts/douyin_groupbuy_pipeline.py select \
  --account <douyin_account> \
  --groupid <laike_groupid> \
  --date "昨天" \
  --metric "商品成交券数" \
  --limit 3 \
  --output /path/to/selection.json \
  --headed
```

常用指标：

- `商品成交券数`
- `商品成交金额`

## 3. 生成图文 brief

```bash
python scripts/douyin_groupbuy_pipeline.py brief \
  --selection /path/to/selection.json \
  --product-index 1 \
  --output-dir /path/to/groupbuy_work \
  --location "<完整POI名称>"
```

生成内容：

- `title.txt`
- `caption.txt`
- `image_prompts.md`
- `publish_meta.json`
- `images/`

## 4. 生图

用 Codex 的 `imagegen` skill 读取 `image_prompts.md`。每个商品建议生成 3-5 张竖版图文海报，放入 `images/`。

## 5. 发布

```bash
python scripts/douyin_groupbuy_pipeline.py publish \
  --account <douyin_account> \
  --work-dir /path/to/groupbuy_work \
  --location "<完整POI名称>" \
  --bgm auto \
  --headed
```

首次跑新账号或新 POI 时保留 `--headed`，便于观察验证码、风控和位置候选。
