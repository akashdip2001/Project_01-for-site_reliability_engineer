# Contributing to MyApp

Thanks for your interest in contributing! This document explains how to get started.

## Getting Started

```bash
git clone <your-repo-url> && cd myapp
chmod +x repo-setup.sh && ./repo-setup.sh
```

## Branch Naming Convention

| Type | Format | Example |
|------|--------|---------|
| Feature | `feat/<short-description>` | `feat/add-auth-endpoint` |
| Bug fix | `fix/<short-description>` | `fix/cors-header-missing` |
| Infra | `infra/<short-description>` | `infra/add-waf-rules` |
| Docs | `docs/<short-description>` | `docs/update-readme` |

## Workflow

1. Create a branch from `main` using the naming convention above.
2. Make your changes. Ensure pre-commit hooks pass.
3. Push and open a Pull Request using the PR template.
4. Address review feedback from CODEOWNERS.
5. Squash-merge into `main` after approval.

## Code Standards

- **Python**: Follow PEP 8. Use type hints.
- **JavaScript**: Use `const`/`let`, no `var`. No unused variables.
- **Terraform**: Run `terraform fmt` before committing. Use variables for all configurable values.
- **Kubernetes**: Always set resource requests/limits and health probes.
- **Docker**: Use slim/alpine bases. Run as non-root. No secrets in images.

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add user authentication endpoint
fix: resolve CORS issue on /api/data
infra: add WAF rules to ALB
docs: update deployment instructions
```
