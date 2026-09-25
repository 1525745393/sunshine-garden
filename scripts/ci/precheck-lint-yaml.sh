#!/usr/bin/env bash
source "$(dirname "$0")/_common.sh"

# require_tool 在 yamllint 缺失时会 exit 0 + warning，本行之后的代码不会执行
require_tool yamllint

# 切换到项目根目录：yamllint 配置文件 .yamllint 与 workflow glob 均相对项目根
PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$PROJECT_ROOT"

log_info "执行 yamllint -c .yamllint .github/workflows/*.yml"

# 为什么指定 -c .yamllint：使用项目自定义规则（禁用 line-length / truthy 等），
# 而非 yamllint 默认规则，避免对 GitHub Actions 配置文件误报
if ! yamllint -c .yamllint .github/workflows/*.yml; then
    log_error "yamllint 发现问题"
    exit 1
fi

log_success "yamllint 通过"
exit 0
