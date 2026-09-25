#!/usr/bin/env bash
source "$(dirname "$0")/_common.sh"

# 切换到项目根目录
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-/dev/null}"

# ============================================================
# sunshine-garden 版安全检查
# （纯 Flutter 应用，无 Python 后端，故不使用 bandit）
# 检查目标：
#   1. lib/ 与 scripts/ 中疑似硬编码的密钥/令牌字面量
#   2. .github/workflows/ 中是否出现字面量 Token（应使用 ${{ secrets.* }}）
# ============================================================

log_info "执行硬编码敏感信息扫描（lib/ 与 scripts/）"

# 匹配 pattern：键名（api_key / secret / password / token 等）后跟字符串字面量（长度 >= 8）
# 使用双引号包裹，内部 \"/' 分别转义单双引号
PATTERN="(api[_-]?key|secret|password|passwd|token)[[:space:]]*[:=][[:space:]]*[\"'][^\"']{8,}"

# grep 在 if 条件中不受 set -e 影响；2>/dev/null 忽略无匹配目录
violations=$(grep -rnE --include='*.dart' --include='*.sh' -e "$PATTERN" lib scripts 2>/dev/null || true)

if [ -n "$violations" ]; then
    log_error "检测到疑似硬编码敏感信息："
    echo "$violations"
    {
        echo "## 敏感信息扫描"
        echo ""
        echo "❌ 检测到疑似硬编码的密钥/令牌，请移除并改用环境变量或 GitHub Secrets："
        echo ""
        echo '```'
        echo "$violations"
        echo '```'
    } >> "$SUMMARY_FILE"
    exit 1
fi

log_info "检查工作流中是否直接引用了字面量 Token（应使用 secrets.*）"

# GitHub 常见 token 前缀：ghp_（PAT）、github_pat_（fine-grained PAT）、gho_（OAuth）
literal_tokens=$(grep -rnE 'ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|gho_[A-Za-z0-9]{20,}' .github/workflows/ 2>/dev/null || true)

if [ -n "$literal_tokens" ]; then
    log_error "检测到工作流中包含字面量 Token，必须改用 \${{ secrets.* }}"
    echo "$literal_tokens"
    exit 1
fi

{
    echo "## 敏感信息扫描"
    echo ""
    echo "✅ 未检测到硬编码密钥 / 字面量 Token"
} >> "$SUMMARY_FILE"

log_success "安全检查通过"
exit 0
