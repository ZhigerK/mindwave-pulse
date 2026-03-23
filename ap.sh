#!/bin/bash
set -euo pipefail

PATCH_FILE="${1:-}"

if [ -z "$PATCH_FILE" ]; then
  echo "[ERROR] Usage: ./ap.sh <patch_file.js>"
  exit 1
fi

if [ ! -f "$PATCH_FILE" ]; then
  echo "[ERROR] Patch file not found: $PATCH_FILE"
  exit 1
fi

echo "[INFO] [ROOT] Applying Patch (transit): $PATCH_FILE"
node "$PATCH_FILE"

echo "[INFO] [ROOT] Verifying..."

# Вспомогательная функция для проверки наличия скрипта в package.json
has_npm_script() {
  grep -q "\"$1\":" package.json
}

# 1. LINT
echo "   > Linting..."
if has_npm_script "lint"; then
  if ! npm run lint; then
    echo "[ERROR] [ROOT] Lint check failed!"
    echo "[WARN]  Changes NOT committed. Run './rb.sh' to rollback."
    exit 1
  fi
else
  echo "[WARN]  [ROOT] No 'lint' script found in package.json. Skipping."
fi

# 2. UNIT TESTS
echo "   > Unit Tests..."
if has_npm_script "test"; then
    if ! npm run test; then
        echo "[ERROR] [ROOT] Unit Tests failed!"
        echo "[WARN]  Changes NOT committed. Run './rb.sh' to rollback."
        exit 1
    fi
else
    echo "[WARN]  [ROOT] No 'test' script found in package.json. Skipping."
fi

# 3. BUILD
echo "   > Building..."
if has_npm_script "build"; then
  if ! npm run build; then
    echo "[ERROR] [ROOT] Build check failed!"
    echo "[WARN]  Changes NOT committed. Run './rb.sh' to rollback."
    exit 1
  fi
else
  echo "[WARN]  [ROOT] No 'build' script found in package.json. Skipping."
fi

echo "[OK] Verification Passed."

# --- PATCH ID EXTRACTION ---
PATCH_ID=""

# Ищем строку с PATCH_ID и извлекаем значение между одинарными или двойными кавычками
PATCH_ID=$(grep -E "^const PATCH_ID\s*=" "$PATCH_FILE" | sed -E "s/const PATCH_ID\s*=\s*['\"]([^'\"]+)['\"];?/\1/" | head -n 1 || true)

if [ -z "$PATCH_ID" ]; then
  echo "[ERROR] Could not determine PATCH_ID."
  echo "[INFO]  Ensure inside file there is: const PATCH_ID = 'YOUR_ID';"
  exit 1
fi

# --- ARCHIVING ---
mkdir -p patches/history
DEST="patches/history/patch_${PATCH_ID}.js"

if [ -f "$DEST" ]; then
  echo "[ERROR] Destination already exists: $DEST"
  echo "[INFO]  Refusing to overwrite. Change PATCH_ID or delete existing file."
  exit 1
fi

cp "$PATCH_FILE" "$DEST"
echo "[OK] [ROOT] Archived patch copy: $DEST"