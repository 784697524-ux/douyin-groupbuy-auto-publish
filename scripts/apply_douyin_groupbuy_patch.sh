#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runtime="${SOCIAL_AUTO_UPLOAD_HOME:-$HOME/.openclaw/workspace/social-auto-upload}"
patch_file="$repo_dir/patches/douyin-groupbuy-location.patch"
video_patch_file="$repo_dir/patches/douyin-video-location-fix.patch"
single_browser_patch_file="$repo_dir/patches/douyin-single-browser-publish.patch"

if [ ! -d "$runtime/.git" ]; then
  echo "runtime is not a git checkout: $runtime" >&2
  exit 1
fi

if [ ! -f "$patch_file" ]; then
  echo "missing patch: $patch_file" >&2
  exit 1
fi

if [ ! -f "$video_patch_file" ]; then
  echo "missing patch: $video_patch_file" >&2
  exit 1
fi

if [ ! -f "$single_browser_patch_file" ]; then
  echo "missing patch: $single_browser_patch_file" >&2
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

if git -C "$runtime" apply --reverse --check "$video_patch_file" >/dev/null 2>&1; then
  echo "douyin video location fix already applied: $runtime"
else
  git -C "$runtime" apply --check "$video_patch_file"
  git -C "$runtime" apply "$video_patch_file"
  echo "applied douyin video location fix: $runtime"
fi

if git -C "$runtime" apply --reverse --check "$single_browser_patch_file" >/dev/null 2>&1; then
  echo "douyin single-browser publish fix already applied: $runtime"
else
  git -C "$runtime" apply --check "$single_browser_patch_file"
  git -C "$runtime" apply "$single_browser_patch_file"
  echo "applied douyin single-browser publish fix: $runtime"
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
  tests.test_sau_browser_cli.DouyinSingleBrowserPublishTests \
  tests.test_douyin_product_selector
popd >/dev/null

echo "douyin group-buy CLI is ready. Use: ./bin/douyin-groupbuy publish-video ... --location \"杭州中大银泰百货\" --headed"
