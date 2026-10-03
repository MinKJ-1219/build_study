# 3-4 실습: Bazel --profile 결과(JSON trace)에서 빌드 단계별 소요 시간과
# 가장 오래 걸린 작업 상위 N개를 출력한다.
# (Bazel 9에서는 `bazel analyze-profile` 명령이 제거되어 직접 파싱한다)
# 사용법: python3 tools/profile_phases.py <profile.json.gz> [상위 개수=15]
import gzip
import json
import sys

events = json.load(gzip.open(sys.argv[1]))["traceEvents"]
top_n = int(sys.argv[2]) if len(sys.argv) > 2 else 15

# 1) "build phase marker" 이벤트 = 각 단계의 시작 시점
phases = sorted(
  [e for e in events if e.get("cat") == "build phase marker"], key=lambda e: e["ts"]
)
end = max(e["ts"] + e.get("dur", 0) for e in events if "ts" in e)

print("== 단계별 시간")
for cur, nxt in zip(phases, phases[1:] + [{"ts": end}]):
  print(f"{cur['name']:<50}{(nxt['ts'] - cur['ts']) / 1e6:7.2f}s")

# 2) 길이(dur)가 있는 개별 작업 중 오래 걸린 순서
#    전체 구간을 감싸는 상위 이벤트(빌드 자체, 스레드 이름 등)는 제외
spans = [
  e for e in events
  if e.get("ph") == "X" and e.get("dur") and e.get("cat") != "build phase marker"
]
spans.sort(key=lambda e: e["dur"], reverse=True)

print(f"\n== 오래 걸린 작업 상위 {top_n}개 (카테고리 | 이름)")
for e in spans[:top_n]:
  name = e.get("name", "")[:70]
  print(f"{e['dur'] / 1e6:7.2f}s  {e.get('cat', '-'):<28}| {name}")
