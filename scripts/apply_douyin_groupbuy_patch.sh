#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runtime="${SOCIAL_AUTO_UPLOAD_HOME:-$HOME/.openclaw/workspace/social-auto-upload}"
patch_file="$repo_dir/patches/douyin-groupbuy-location.patch"

if [ ! -d "$runtime/.git" ]; then
  echo "runtime is not a git checkout: $runtime" >&2
  exit 1
fi

if [ ! -f "$patch_file" ]; then
  echo "missing patch: $patch_file" >&2
  exit 1
fi

if [ -f "$runtime/uploader/douyin_uploader/location_picker.py" ] \
  && grep -q "_location_option_score" "$runtime/uploader/douyin_uploader/location_picker.py" \
  && grep -q "select-groupbuy-products" "$runtime/sau_cli.py"; then
  echo "douyin group-buy patch already present: $runtime"
elif git -C "$runtime" apply --unidiff-zero --reverse --check "$patch_file" >/dev/null 2>&1; then
  echo "douyin group-buy patch already applied: $runtime"
else
  git -C "$runtime" apply --unidiff-zero --check "$patch_file"
  git -C "$runtime" apply --unidiff-zero "$patch_file"
  echo "applied douyin group-buy patch: $runtime"
fi

pushd "$runtime" >/dev/null
"$runtime/.venv/bin/python" -m py_compile \
  sau_cli.py \
  uploader/douyin_uploader/main.py \
  uploader/douyin_uploader/location_picker.py \
  uploader/douyin_uploader/music_picker.py \
  uploader/douyin_uploader/product_selector.py
"$runtime/.venv/bin/python" -m unittest \
  tests.test_sau_browser_cli.BrowserCliParserTests.test_douyin_upload_video_accepts_location \
  tests.test_sau_browser_cli.BrowserCliParserTests.test_douyin_upload_note_accepts_location \
  tests.test_sau_browser_cli.BrowserCliParserTests.test_douyin_select_groupbuy_products_defaults_to_coupon_count \
  tests.test_sau_browser_cli.BrowserCliDispatchTests.test_dispatch_douyin_upload_note_uses_new_request_fields \
  tests.test_sau_browser_cli.BrowserCliDispatchTests.test_dispatch_douyin_upload_video_uses_dual_thumbnail_request_fields \
  tests.test_sau_browser_cli.BrowserCliDispatchTests.test_dispatch_douyin_select_groupbuy_products_writes_output \
  tests.test_douyin_product_selector
popd >/dev/null

echo "douyin group-buy CLI is ready. Use: sau douyin select-groupbuy-products ... then upload-video/upload-note ... --location \"合肥滨湖银泰百货\" --bgm auto --headed"
