#!/usr/bin/env bash
set -euo pipefail

echo "=== Initializing repository ==="
git init
git branch -M main

echo "=== Formatting Terraform files ==="
cd terraform && terraform fmt -recursive && cd ..

echo "=== Installing pre-commit hook (terraform fmt) ==="
mkdir -p .git/hooks
cat > .git/hooks/pre-commit << 'HOOK'
#!/usr/bin/env bash
set -e
echo "Running terraform fmt check..."
cd terraform && terraform fmt -check -recursive
echo "Running Python lint check..."
if command -v python3 &> /dev/null; then
  python3 -m py_compile src/backend/main.py
fi
HOOK
chmod +x .git/hooks/pre-commit

echo "=== Installing backend dependencies ==="
cd src/backend && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && deactivate && cd ../..

echo "=== Installing frontend dependencies ==="
cd src/frontend && npm install && cd ../..

echo "=== Initial commit ==="
git add .
git commit -m "chore: initial project scaffold"

echo "=== Done! Repository is ready. ==="
