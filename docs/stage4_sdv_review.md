# 4단계 리뷰: SDV 특화 통합 빌드 고려사항

> 작성일: 2026-10-05
> 실습 위치: `practice/week4/`, `practice/vendor_a/`
> 목표: 4-1~4-4에서 만든 것을 정리하고, 3단계 리뷰(`docs/stage3_cicd_review.md` §3)에서 짚었던 "지금 구조가 무너지는 지점"을 실제로 얼마나 고쳤는지, 어디가 여전히 비어있는지 솔직하게 점검한다.

---

## 1. 완성된 결과물

```
practice/week4/
├── toolchain/
│   ├── cc_toolchain_config.bzl   ← 4-1  aarch64-linux-gnu-gcc 도구 경로 + 헤더 검색 경로
│   └── BUILD.bazel               ← 4-1  cc_toolchain + toolchain() + aarch64_linux platform
├── vendor_app.c                  ← 4-2  @vendor_a//:vendor_a_import 소비
├── region_eu.c / region_us.c     ← 4-2  config_setting + select() 변형
├── tools/gen_sbom.sh             ← 4-3  bazel query 기반 최소 SBOM 초안 생성기
└── MODULE.bazel                  ← platforms, vendor_a(local_path_override) 등록

practice/vendor_a/                ← 4-2  "Tier1 공급업체"를 흉내 낸 독립 Bazel 모듈
├── vendor_a.h                    ← 공급업체가 넘기는 유일한 계약
├── libvendor_a.a                 ← 사전 빌드된 바이너리 (소스 .c는 제공 안 함)
└── BUILD.bazel                   ← cc_import로 노출
```

## 2. 단계별 핵심 교훈

| 단계 | 실험 | 교훈 |
|---|---|---|
| 4-1 | `--platforms=//toolchain:aarch64_linux`로 크로스 컴파일 → `file`로 확인 → 네이티브 실행(Exec format error) → `qemu-aarch64`로 재확인 | Bazel의 `toolchain()`은 "어디서 실행되는가"(`exec_compatible_with`)와 "무엇을 만드는가"(`target_compatible_with`)를 분리해서 선언한다. 1단계에서 `gcc`로 겪은 문제가, 선언적 툴체인 레이어에서는 "플랫폼을 잘못 지정했다"는 명시적 신호로 바뀐다. (부가: Bazel 9.2.0에서는 `cc_common`/`CcToolchainConfigInfo`/`cc_toolchain`이 더 이상 암묵적 전역이 아니라 rules_cc에서 명시적으로 load해야 한다 — 공식 튜토리얼 문서가 구버전 기준이라 그대로 따라 하면 깨진다) |
| 4-2 | `vendor_a`를 별도 모듈로 분리해 `local_path_override` + `cc_import`로 통합, `bazel query`로 그래프 비교, `select()`로 리전 전환 | 자체 소스(`:foo`)는 그래프 안에서 파일 단위로 보이지만, 사전 빌드된 `.a`는 **쪼개지지 않는 리프**다 — Bazel에게는 "이 파일이 바뀌었는가"까지만 보이고 "왜/무엇이" 바뀌었는지는 안 보인다. 변형(`select()`)은 플랫폼(`--platforms`)과 **독립된 축**이라는 것도 확인했다 |
| 4-3 | `gen_sbom.sh`로 `:app`과 `:vendor_app`의 구성요소 목록 비교, `bazel mod graph`로 버전 필드 확인 | 추적성에는 "커밋 단위"(`BUILD_INFO.txt`, 3단계)와 "구성요소 단위"(SBOM, 4-3) 두 계층이 있고 **지금은 따로 생성된다**. `local_path_override`는 버전 추적을 생략한다(`vendor_a@_`) — 실제 운영에서는 이게 SBOM의 `component@version` 필드가 돼야 한다 |
| 4-4 | (실습 없음, 개념만) | 캐싱은 "안 해도 되는 일을 줄이고", 원격 실행은 "해야 하는 일을 병렬화한다" — 대규모 코드베이스에서는 둘 다 필요하다. OTA 차분 업데이트가 작으려면 빌드가 결정적이어야 한다(1단계 재현 가능한 빌드 + 3-3 stamping 격리가 전제조건) |

**관통하는 원칙**: 1~3단계에서 세운 원칙(재현 가능한 빌드, 증분 빌드, 캐시, 추적성)은 4단계에서 사라지지 않고, SDV 규모에서 **"있으면 좋은 것"이 "없으면 시스템이 무너지는 것"으로 바뀐다**는 걸 확인하는 단계였다.

## 3. 3단계 스트레스 테스트 재점검: 얼마나 고쳤고, 어디가 비었는가

3단계 리뷰(`docs/stage3_cicd_review.md` §3)에서 식별한 6개 지점을 다시 본다.

| SDV 상황 | 3단계 때 상태 | 4단계에서 고친 것 | 여전히 비어있는 것 |
|---|---|---|---|
| **멀티 타겟** | 호스트 gcc 하나로 x86만 빌드 | Bazel `platforms`/`toolchain`으로 aarch64(HPC/Cortex-A급) 크로스 컴파일 실증 | Cortex-M(MCU, bare-metal, newlib/no-OS)용 툴체인은 전혀 다른 종류라 다루지 않음. AUTOSAR Classic의 ARXML→RTE 코드 생성 파이프라인도 개념만 |
| **공급업체 코드 통합** | 한 저장소, 한 팀 | `vendor_a`를 별도 모듈로 분리해 `local_path_override`로 통합, `cc_import`로 "소스 없는 바이너리" 패턴 실증, `bazel query`로 블랙박스 경계 확인 | 다른 저장소/다른 조직의 변경을 감지하는 `rdeps` 기반 영향 분석은 실제로 안 해봄(모노레포 안에서만 실습). ARXML 같은 코드 생성 기반 인터페이스 계약도 미실습 |
| **변형(Variant) 관리** | 빌드 설정 1종 | `config_setting` + `select()`로 리전 변형 전환 실증 | 축 하나(region)만 다뤘다 — 차종×트림×리전처럼 여러 축이 겹치는 조합 폭발, build matrix는 개념만 |
| **규모** | `actions/cache` (저장소당 용량 제한) | (없음 — 개념만) | `--remote_cache`/RBE 실제 구성은 전혀 안 함. 5단계 ③로 그대로 이연 |
| **기능안전·추적성** | 7일 보관, stamping은 기록만 함 | `gen_sbom.sh`로 구성요소 단위 해시 목록 확보 | `BUILD_INFO.txt`(커밋)와 SBOM(구성요소)이 통합된 단일 레코드가 아님. 불변 장기 저장소, dirty 빌드 차단 게이트 여전히 없음 |
| **사이버보안·공급망** | 116개 모듈을 끌어오지만 목록이 없음 | `gen_sbom.sh` 초안으로 목록은 생김 | 표준 SBOM 포맷(SPDX/CycloneDX) 아님, 서명/무결성 검증 없음, 벤더 쪽 `component@version`이 `local_path_override` 때문에 비어있음 |
| **OTA 업데이트** | tar 하나 | (없음 — 개념만) | 차분 업데이트, 호환성 메타데이터, 신뢰 가능한 버전 관리 모두 개념만 정리하고 실습은 안 함 |

**정직한 결론**: 4단계는 "멀티 타겟"과 "벤더 통합·변형"과 "SBOM 초안"을 **작게나마 실제로 손으로 만들어본** 단계지만, 여전히 세 가지는 명백히 비어있다 — ① 진짜 규모(RBE), ② 표준화된 산출물(SBOM 포맷, 서명), ③ 여러 조직/저장소가 섞인 현실(rdeps 기반 영향 분석). 이 셋은 그대로 5단계로 넘어간다.

## 4. 4단계에서 보류한 것

- AUTOSAR Classic의 ARXML→RTE 코드 생성 파이프라인 실습 (`genrule` 기반으로 짧게 해볼 수 있었지만 생략)
- Cortex-M(bare-metal) 툴체인 — 이번 크로스 컴파일은 Linux 타겟(aarch64)까지만, MCU용 newlib/no-OS 툴체인은 다루지 않음
- 여러 저장소에 걸친 `rdeps` 기반 영향 분석 (벤더 코드가 다른 저장소에 있다는 가정까지는 안 함)
- 변형의 build matrix(여러 축 조합을 CI에서 전부 빌드/테스트)
- `--remote_cache`/RBE 실제 구성, OTA 차분 업데이트 실습 (모두 개념만, 5단계 ①③과 연결)
- 4-5 참고 자료 서베이(SOAFEE, Eclipse SDV, COVESA, AUTOSAR 공식 문서) — 리뷰 작성을 먼저 하기로 하면서 미뤄둠. 필요할 때 키워드로 검색해서 보는 것으로 충분

## 5. 복습 질문과 답안 요점 (자율 복습용)

**Q1. 벤더가 `libvendor_a.a`를 새 버전으로 바꿔서 올렸다면, `gen_sbom.sh`가 그걸 어떻게 감지하는가? 감지 못 하는 건 무엇인가?**
- `libvendor_a.a`의 SHA256 해시가 바뀌므로 SBOM 출력에서 그 줄의 해시가 달라진 걸 바로 알 수 있다 — "뭔가 바뀌었다"는 확인된다.
- 하지만 **왜** 바뀌었는지, 어떤 취약점이 고쳐졌는지/새로 들어왔는지는 벤더가 알려주지 않으면 알 길이 없다. 이게 바로 ISO/SAE 21434가 공급업체에게 **자신들의 컴포넌트에 대한 SBOM**까지 요구하는 이유다 — 우리 SBOM의 "vendor_a" 한 줄 뒤에, 벤더가 가진 더 상세한 SBOM이 연결돼야 완전해진다("SBOM의 SBOM" 체인).

**Q2. `vendor_app`을 `--platforms=//toolchain:aarch64_linux`로 빌드하면 무슨 일이 일어날까?**
- `libvendor_a.a`는 x86_64용으로 빌드된 바이너리다. aarch64 타겟으로 링크를 시도하면 **링크 단계에서 아키텍처 불일치 에러**가 날 것이다(컴파일은 우리 소스만 하면 되니 통과할 수도 있지만, 최종 링크에서 걸린다).
- 이건 스트레스 테스트 표의 "멀티 타겟" 행과 "공급업체 코드 통합" 행이 만나는 지점이다 — **벤더도 우리가 지원하는 타겟 수만큼 바이너리를 따로 공급해야 한다.** 하나라도 빠지면 그 타겟에서만 통합 빌드가 깨진다. (실제로 돌려서 에러 메시지를 보는 것도 좋은 추가 확인이 될 것이다.)

**Q3. 지금 만든 산출물(`BUILD_INFO.txt`, SBOM 초안, region 변형, aarch64 바이너리)을 ISO 26262/21434 심사관에게 보여준다면 뭐가 부족한가?**
- **통합된 단일 레코드가 없다** — 커밋 추적성(`BUILD_INFO.txt`)과 구성요소 추적성(SBOM)이 따로 생성되는 별개 파일이다.
- **불변 장기 보관이 없다** — 3단계의 `retention-days: 7` 문제가 그대로다. 심사 시점에 원본 바이너리가 이미 없을 수 있다.
- **표준 포맷이 아니다** — 실무 SBOM은 SPDX/CycloneDX 같은 기계가 읽을 수 있는 포맷을 요구한다. 지금은 사람이 읽는 텍스트 표다.
- **서명/무결성 검증이 없다** — 해시는 있지만 "이 해시 목록 자체가 조작되지 않았다"를 보장하는 서명이 없다.
- **벤더 쪽 버전 필드가 비어있다** — `local_path_override`를 실습용으로 썼기 때문에 `vendor_a@_`로 나온다. 실제 레지스트리 모듈이었다면 해결됐을 문제다.

---

4단계는 "SDV가 일반 빌드와 다른 지점"을 **직접 만들어보고 한계까지 확인한** 단계였다. 다음 5단계는 여기서 비어있는 것(①③, 그리고 멀티 타겟+벤더+변형+SBOM을 하나의 미니 프로젝트로 통합)을 실제로 채워보는 단계다.

## 6. 참고 자료 서베이 (4-5, 2026-10-05 진행)

4개 키워드를 검색해서, 지금까지 실습한 것과 어떻게 연결되는지 중심으로 정리했다. (실습 없음, 추후 필요할 때 다시 검색해서 깊이 들어가는 용도)

### SOAFEE (Scalable Open Architecture for the Embedded Edge)
- Arm이 2021년 시작한 산업 이니셔티브. **"클라우드에서 쓰는 도구(컨테이너, 오케스트레이션, CI/CD)로 차량 워크로드를 개발·테스트하고, 그걸 그대로 차량 하드웨어에 배포한다"**는 게 목표 — 컨테이너 오케스트레이션과 자동차 기능안전을 처음으로 결합한 레퍼런스 구현을 제공한다. 회원사 120개 이상(완성차·반도체·클라우드 업체).
- **우리 실습과의 연결**: 4-4에서 "원격 캐시/RBE가 왜 필수인가"를 개념으로만 다뤘는데, SOAFEE는 바로 이 문제(HPC급 SDV 소프트웨어를 클라우드 스케일로 빌드·테스트하면서 차량에 배포할 산출물과 동일하게 유지하는 것)에 대한 업계의 실제 답이다. Adaptive AUTOSAR(4-1에서 다룸)가 이 아키텍처의 소프트웨어 쪽 반쪽이라면, SOAFEE는 그걸 클라우드 네이티브 빌드/배포 파이프라인과 묶는 쪽.
- 더 파고들 키워드: "SOAFEE reference implementation", "mixed-criticality containers"

### Eclipse SDV 워킹그룹
- Eclipse Foundation 산하, OEM/Tier1/기술업체 50개 이상이 참여해 25개 이상의 오픈소스 프로젝트를 진행 중(Eclipse S-CORE, iceoryx, Zenoh, openDuT, Autowrx 등). 2026년에 S-CORE 0.7.0이 릴리스됐고, "SDV End-to-End Demo Blueprint"라는 **재현 가능한(reproducible) 전체 데모 레퍼런스**를 공개했다.
- **우리 실습과의 연결**: Eclipse S-CORE는 정확히 우리가 4단계에서 미니어처로 건드려본 문제(벤더 코드 통합, 변형 관리, 추적성)를 업계 표준 수준에서 풀려는 시도다. "End-to-End Demo Blueprint"는 우리의 `docs/stage4_sdv_review.md`가 다루는 범위를 실제 업계 레퍼런스로 확장한 모습이라고 볼 수 있다 — 5단계 미니 프로젝트를 설계할 때 구조를 참고할 만하다.
- 더 파고들 키워드: "Eclipse S-CORE", "Eclipse SDV blueprint"

### COVESA (Connected Vehicle Systems Alliance)
- 차량 데이터 표준화에 집중하는 얼라이언스. 핵심 산출물은 **VSS(Vehicle Signal Specification)** — 차량 신호를 위한 표준 스키마 — 와 VDM(Vehicle Data Model)/S2DM. 2026년 CES에서 Elektrobit·Moter·Sonatus 등이 VSS를 적용한 상용 제품을 전시.
- **우리 실습과의 연결**: COVESA/VSS는 빌드 시스템 자체보다는 4-2에서 다룬 "인터페이스 계약" 문제의 표준화 버전이다 — 서로 다른 Tier1/Tier2/OEM이 신호 하나를 두고 다르게 해석하지 않도록 스키마를 표준화해두면, 그 스키마에서 코드 생성(4-2 "코드 생성 도구 연계")이 자동화될 수 있다. 우리 `vendor_a.h`는 이 역할을 가장 작은 형태로 흉내 낸 것이다.
- 더 파고들 키워드: "Vehicle Signal Specification", "COVESA VSS tooling"

### AUTOSAR 공식 문서
- 4-1에서 다룬 Classic/Adaptive 구분이 여전히 핵심 축. Adaptive Platform은 2016년 작업 시작, 현재는 연 단위 릴리스 체계(R23-11, R24-11, R25-11 — 연도-월 표기)로 운영된다. `ara::com`(서비스 통신 미들웨어) 쪽에 코드 생성기·매니페스트 생성 도구들이 정리돼 있다.
- **우리 실습과의 연결**: 4-2에서 "코드 생성 도구 연계"를 개념으로만 남겨뒀는데, `ara::com` 코드 생성기가 바로 그 실체다 — ARXML 인터페이스 정의를 입력받아 통신 바인딩 코드를 생성하고, 그 생성된 코드가 빌드 그래프에 들어간다.
- 더 파고들 키워드: 공식 사이트 autosar.org의 "AUTOSAR_EXP_SWArchitecture" 설명 문서

Sources: [SOAFEE for Software Defined Vehicles](https://www.adlinktech.com/en/soafee) · [Arm: SOAFEE](https://www.arm.com/company/success-library/made-possible/soafee) · [Eclipse SDV newsroom](https://newsroom.eclipse.org/tags/sdv) · [About Eclipse SDV](https://eclipsesdv.org/about/) · [COVESA](https://covesa.global/) · [COVESA at CES 2026](https://covesa.global/covesa-at-ces-2026/) · [AUTOSAR (Wikipedia)](https://en.wikipedia.org/wiki/AUTOSAR) · [AUTOSAR AP R21-11 Software Architecture](https://www.autosar.org/fileadmin/standards/R21-11/AP/AUTOSAR_EXP_SWArchitecture.pdf)
