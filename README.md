# Kopring — Claude Code Plugin

Gradle + Kotlin 기반 Spring Boot 프로젝트를 위한 Claude Code 플러그인입니다.
Worktree 관리, 데스크탑 알림, 기능 개발 스킬을 제공합니다.

## 설치

```bash
claude plugin install github:hoyeon/kopring
```

## 제공 기능

### Hooks

| 이벤트 | 스크립트 | 설명 |
|--------|----------|------|
| `WorktreeCreate` | `worktree-add.sh` | `feat/<name>` 브랜치로 git worktree 자동 생성 |
| `PermissionRequest` | `notify-permission.sh` | 권한 확인 필요 시 Windows 트레이 알림 |
| `Stop` | `notify-stop.sh` | 작업 완료 시 Windows 트레이 알림 |

### Skills

| 스킬 | 설명 |
|------|------|
| `/feat` | Spring Boot 기능 개발 3단계 워크플로우 (계획 → 구현 → PR) |

## 필수 의존성

| 도구 | 최소 버전 | 용도 |
|------|-----------|------|
| `git` | 2.30+ | worktree 관리 |
| `jq` | 1.6+ | hook JSON 파싱 |
| `gh` | 2.0+ | PR 생성 (`/feat` 스킬) |
| `java` | 17+ | Spring Boot 빌드/실행 |

> 알림 훅(`notify-permission.sh`, `notify-stop.sh`)은 WSL2에서 `powershell.exe`를 사용합니다. Windows 10/11이면 별도 설치 불필요.

### WSL2 / Linux

```bash
sudo apt-get install -y jq gh openjdk-21-jdk

# gh 인증
gh auth login
```

### macOS

```bash
brew install jq gh openjdk@21

# gh 인증
gh auth login
```
