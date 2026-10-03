# 3-4 실습: Bazel --profile 결과(JSON trace)에서 빌드 단계별 소요 시간을 출력한다.
# (Bazel 9에서는 `bazel analyze-profile` 명령이 제거되어 직접 파싱한다)
# 사용법: python3 tools/profile_phases.py <profile.json.gz>
import gzip
import json
import sys

events = json.load(gzip.open(sys.argv[1]))["traceEvents"]

# "build phase marker" 이벤트 = 각 단계의 시작 시점
phases = sorted(
  [e for e in events if e.get("cat") == "build phase marker"], key=lambda e: e["ts"]
)
end = max(e["ts"] + e.get("dur", 0) for e in events if "ts" in e)

for cur, nxt in zip(phases, phases[1:] + [{"ts": end}]):
  print(f"{cur['name']:<50}{(nxt['ts'] - cur['ts']) / 1e6:7.2f}s")
