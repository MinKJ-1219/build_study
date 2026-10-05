#!/usr/bin/env bash
# 3-3 실습: Bazel stamping용 워크스페이스 상태 스크립트.
# `--stamp`로 빌드할 때 Bazel이 이 스크립트를 실행하고, 출력된 "키 값" 줄을
# bazel-out/stable-status.txt(STABLE_ 접두사) / volatile-status.txt(그 외)에 기록한다.
set -euo pipefail

# STABLE_ 키: 값이 바뀌면 이 값을 쓰는 타겟을 다시 빌드한다
echo "STABLE_GIT_COMMIT $(git rev-parse HEAD)"
echo "STABLE_GIT_DIRTY $(test -z "$(git status --porcelain .)" && echo clean || echo dirty)"
echo "STABLE_BUILD_VERSION ${BUILD_VERSION:-0.1.0-local}"
