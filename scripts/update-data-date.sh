#!/bin/bash
# pre-commit から呼ばれ、ステージ中の DATA ブロックが HEAD と異なるときだけフッターの日付を当日に更新する
set -e
FILE=index.html
cd "$(git rev-parse --show-toplevel)"

git diff --cached --quiet -- "$FILE" && exit 0

data_block() { sed -n '/^const DATA = \[/,/^\];$/p'; }
if diff -q <(git show "HEAD:$FILE" 2>/dev/null | data_block) <(git show ":$FILE" | data_block) >/dev/null; then
  exit 0
fi

TODAY=$(date +%F)
PATTERN="s/\\([0-9]{4}-[0-9]{2}-[0-9]{2} 時点\\)/($TODAY 時点)/"

# 作業ツリーの未ステージ変更を巻き込まないよう、ステージ済みの内容だけを書き換えて index に戻す
BLOB=$(git show ":$FILE" | sed -E "$PATTERN" | git hash-object -w --stdin)
git update-index --cacheinfo "100644,$BLOB,$FILE"
sed -i -E "$PATTERN" "$FILE"
echo "📅 DATA が変更されたため、フッターの日付を $TODAY に更新しました"
