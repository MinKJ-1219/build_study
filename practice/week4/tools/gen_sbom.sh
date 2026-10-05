#!/usr/bin/env bash
# 4-3 실습: bazel query로 빌드 그래프에서 소스 구성요소를 뽑아 최소 SBOM 초안을 만든다.
#
# @bazel_tools//... 는 Bazel 자체의 빌드 도구(컴파일러 드라이버 보조 스크립트 등)라
# "이 바이너리의 공급망"이 아니므로 SBOM에서 제외한다. 그 외에 남는 것은
# 1) 우리 저장소 소스(//...), 2) 외부 모듈 소스(@vendor_a//... 같은 것) 뿐이다.
set -euo pipefail

TARGET="${1:-//:vendor_app}"

echo "# SBOM draft for ${TARGET}"
echo "# generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "# source commit: $(git rev-parse HEAD 2>/dev/null || echo unknown)"
echo
printf '%-20s  %-64s  %s\n' "COMPONENT" "SHA256" "ORIGIN"

bazel query "kind('source file', deps(${TARGET}))" --output=location 2>/dev/null \
  | grep -v '@bazel_tools' \
  | awk -F':1:1: source file ' '{print $1 "\t" $2}' \
  | while IFS=$'\t' read -r filepath label; do
      if [[ "$label" == @vendor_a* ]]; then
        origin="vendor_a (외부 모듈, no-source 전달)"
      else
        origin="week4_sdv_demo (1st-party)"
      fi
      hash="$(sha256sum "$filepath" 2>/dev/null | cut -d' ' -f1)"
      printf '%-20s  %-64s  %s\n' "$(basename "$filepath")" "${hash:-<unreadable>}" "$origin"
    done
