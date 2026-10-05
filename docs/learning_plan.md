# SDV 통합 소프트웨어 빌드 학습 계획

> 작성일: 2026-09-18
> 목표: 소프트웨어 빌드의 기본 개념을 체계적으로 학습하고, 이를 바탕으로 SDV(Software Defined Vehicle) 통합 소프트웨어 빌드 업무에 필요한 지식을 갖춘다.

## 전체 로드맵 (5단계)

```
1단계: 빌드의 본질 이해        (1주)
2단계: 빌드 시스템 도구 실습     (2주)  ← Make/CMake → Bazel
3단계: CI/CD와 빌드의 결합      (1주)
4단계: SDV 특화 통합 빌드 고려사항 (2주)
5단계: 실전 미니 프로젝트       (1~2주)
```

각 단계는 개념 학습 → 실습 → 리뷰 순으로 진행한다. 단계가 끝날 때마다 실습 코드를 리뷰하거나, 막히는 개념을 구체적인 예제로 파고드는 방식으로 진행한다.

---

## 1단계: 소프트웨어 빌드의 본질 (약 1주)

**목표**: "빌드란 무엇인가"를 도구 없이도 설명할 수 있는 수준

- **컴파일 파이프라인**: 전처리(preprocessing) → 컴파일(compile) → 어셈블(assemble) → 링크(link)의 각 단계에서 무엇이 입력/출력되는지 (예: `.c` → `.i` → `.s` → `.o` → 실행파일)
- **정적 링킹 vs 동적 링킹**: 라이브러리(.a/.lib vs .so/.dll)가 빌드 결과물 크기·배포 방식에 미치는 영향
- **빌드 그래프(DAG)**: 소스 파일·중간 산출물·최종 아티팩트 사이의 의존성을 그래프로 표현하는 개념 — 이후 모든 빌드 도구(Make, Bazel, Gradle)가 이 개념 위에서 동작
- **증분 빌드(incremental build)**: 변경된 부분만 다시 빌드하는 원리, 타임스탬프 기반 vs 콘텐츠 해시 기반 변경 감지 차이
- **재현 가능한 빌드(reproducible/hermetic build)**: 동일한 입력이면 항상 동일한 출력이 나와야 한다는 원칙 — 왜 중요한지(디버깅, 보안, 캐싱)
- **크로스 컴파일**: 빌드를 수행하는 머신(host)과 결과물이 실행될 머신(target)이 다를 때 필요한 개념 — SDV에서 필수

**추천 실습**: `gcc`로 직접 `-E`, `-S`, `-c` 플래그를 써보며 각 단계 산출물을 눈으로 확인

---

## 2단계: 빌드 시스템 도구 (약 2주)

**목표**: Make의 한계를 체감하고, Bazel의 설계 철학을 이해

### 2-1. Make/CMake (1주 이내, 빠르게 훑기) — ✅ 완료 (2026-09-19)
- Makefile의 타겟-의존성-레시피 구조, 암묵적 규칙, `.PHONY` — `practice/week2/01_make/`
- CMake가 Make 위에서 어떤 추상화를 제공하는지 (플랫폼 독립적 빌드 스크립트 생성) — `practice/week2/02_cmake/`. `add_library`+`target_link_libraries`(PUBLIC/PRIVATE)로 라이브러리 분리 구조까지 실습
- 이것들의 한계: 대규모 멀티 언어/멀티 팀 모노레포에서의 확장성 문제, 캐시 무효화 문제, 재현성 부족

### 2-2. Bazel 심화 (핵심, 1~1.5주) — ✅ 완료 (2026-09-19, 원격 실행·멀티언어는 개념만 다룸)

- **핵심 개념**: `WORKSPACE`/`MODULE.bazel`(Bzlmod), `BUILD.bazel` 파일, 타겟(target), 규칙(rule), 레이블(`//path/to:target`) — `practice/week2/03_bazel/`
- **빌드 그래프의 명시성**: Bazel이 왜 "모든 의존성을 명시하라"고 강제하는지 → 정확한 증분 빌드와 캐싱을 가능하게 함. `bazel query "deps(...)"`/`"rdeps(...)"`로 그래프 조회, 테스트 영향 분석과의 연결까지 실습
- **원격 캐싱(Remote Caching)**: 팀/CI 전체가 빌드 결과물을 공유해 재빌드를 줄이는 구조. `--disk_cache`로 두 워크스페이스 간 캐시 공유를 직접 재현. 실제 `--remote_cache` 프로토콜/서버 구성은 개념으로만 다룸
- **원격 실행(Remote Execution, RBE)**: 빌드 자체를 분산 실행해 대규모 코드베이스의 빌드 시간을 단축하는 구조 — SDV처럼 코드량이 매우 큰 환경에서 특히 중요. ⚠️ 실제 클러스터(Buildbarn/BuildBuddy 등)가 필요해 **개념 설명만 진행, 실습은 보류**
- **Hermeticity(격리성)**: Bazel이 샌드박스로 빌드를 격리해 "내 컴퓨터에서는 되는데" 문제를 원천 차단하는 방식. 선언 안 된 헤더 파일이 샌드박스에서 실제로 안 보이는 것을 실패→해결 순서로 확인. Hermetic test 개념(`TEST_TMPDIR`, 테스트 결과 캐싱, `requires-network` 태그)까지 확장
- **멀티 언어 지원**: C/C++, Python 등 다양한 언어/툴체인을 하나의 빌드 그래프로 통합하는 능력 (SDV처럼 AUTOSAR C++, Python 툴링, 임베디드 C가 섞인 환경에 적합). ⚠️ **개념만 언급, 실습(예: py_library 추가)은 아직 안 함**

**추천 실습**: 작은 C++ 프로젝트(예: 라이브러리 2개 + 실행파일 1개)를 Bazel로 빌드해보고, 일부러 소스 하나만 수정해 증분 빌드 로그를 관찰 → 완료 (`:foo` 라이브러리 + `:app` 실행파일 + `:hermetic_demo`)

---

## 3단계: CI/CD와 빌드의 결합 (약 1주)

**목표**: "로컬 빌드"가 "파이프라인 빌드"로 확장될 때 생기는 이슈를 이해

- CI 파이프라인의 기본 단계: checkout → build → test → package → artifact 저장
- 빌드 에이전트/러너의 개념, 빌드 환경의 일관성 확보(컨테이너화, 고정 툴체인 버전)
- 아티팩트 리포지토리(예: Artifactory, Nexus)와 버전 관리 전략
- 캐시 전략을 CI에 어떻게 연결하는지 (Bazel 원격 캐시를 CI 러너들이 공유)
- 빌드 실패의 재현성: "CI에서만 실패한다"는 문제를 줄이는 방법

**추천 실습**: GitHub Actions(또는 GitLab CI)로 간단한 워크플로를 만들어 위 Bazel 프로젝트를 빌드/테스트하는 파이프라인 구성

### 3단계 세부 진행안 (2026-10-03 준비)

실습 위치: `practice/week3/` (2주차 Bazel 프로젝트를 복사해 확장) + 저장소 루트의 `.github/workflows/`
실행 환경: GitHub Actions(공개 저장소 `MinKJ-1219/build_study` → 러너 무료), 로컬 검증은 WSL Bazel 9.2.0

- [x] **3-1. 첫 파이프라인** (2026-10-03 완료): CI 기본 단계(checkout → build → test) 개념, `cc_test` 타겟 추가, push 시 `bazel build //...`/`bazel test //...`를 돌리는 워크플로(`.github/workflows/week3-ci.yml`) 작성 → Actions 로그 읽기. 로직 실패(Test 스텝 FAIL)와 문법 오류(Build 스텝 FAIL, Test skipped)를 직접 비교. 경로 필터(`paths:`)의 한계와 `rdeps` 기반 영향 분석의 필요성 정리
- [x] **3-2. 빌드 환경 일관성** (2026-10-03 완료): 러너 OS 고정(`runs-on: ubuntu-24.04`), 저장소 `.bazelrc`로 로컬/CI 옵션 통일(`--config=ci`: `--announce_rc`, `--lockfile_mode=error`), `:toolchain_info`로 호스트 gcc 자동 감지 문제와 `__DATE__` redacted 확인. `:config_test`로 "로컬 절대 경로 하드코딩 → CI에서만 실패"를 재현하고 `data` 선언 + runfiles 상대 경로로 수정. 컨테이너 잡·hermetic 툴체인(해시 고정)은 개념만 다룸(→ 5단계 크로스 컴파일에서 실습)
- [x] **3-3. Package & Artifact** (2026-10-03 완료): `rules_pkg`의 `pkg_tar`로 `:app_pkg`(app + BUILD_INFO.txt, mtime 고정) 패키징, `--config=release`(`--stamp` + `tools/workspace_status.sh`)로 git 커밋·dirty 여부·버전(`0.1.<run_number>`)을 산출물에 기록, `actions/upload-artifact`로 패키지와 test.xml/test.log 업로드(`if: always()`로 실패 시에도 리포트 보존, 테스트 실패 시 Package는 skipped). 버전 전략·Artifactory/Nexus·양산 SW 장기 보관(UN R156)·dirty 빌드와 추적성 정리
- [x] **3-4. CI 캐시 전략** (2026-10-03 완료): `actions/cache`로 disk/repository/bazelisk 캐시 공유(키 = OS + `.bazelversion`/lock 해시 + 커밋 SHA, `restore-keys` 접두사 폴백). 주석만 바꾸면 컴파일 1건만 재실행되고 링크·테스트는 캐시 hit(early cutoff) 확인. **캐시를 붙여도 CI Build가 줄지 않음** → `--profile` + `tools/profile_phases.py`로 측정 → 간접 의존성 `rules_cc → rules_apple → rules_swift`의 Swift 툴체인 자동 감지가 러너에 설치된 swiftc 때문에 약 36초 소요(환경 감지 결과는 캐시 불가)임을 발견 → `common:ci --repo_env=PATH=/usr/bin:/bin`으로 해결. **Build 50~56초 → 8~11초, Job 67~78초 → 21~23초.** `actions/cache` vs `--remote_cache`(액션 단위 조회, 공유 범위)는 개념으로 정리
- [x] **3-5. 리뷰** (2026-10-03 완료): 파이프라인 전체를 SDV 관점(멀티 타겟, 공급업체 코드, 변형, 규모, 안전·보안, OTA)으로 다시 보며 4단계로 연결 — `docs/stage3_cicd_review.md`. 복습 질문 3개는 답안 요점과 함께 문서에 남김(자율 복습)

---

## 4단계: SDV 특화 통합 빌드 고려사항 (약 2주)

실무 핵심 단계. SDV 통합 빌드가 일반 소프트웨어 빌드와 다른 지점들을 정리한다.

### 4-1. 아키텍처 배경 지식
- **AUTOSAR Classic vs Adaptive**: Classic은 정적 설정/코드 생성 기반, Adaptive는 POSIX 기반 서비스지향 아키텍처 — 빌드 방식이 근본적으로 다름
- **ECU/도메인 컨트롤러/HPC(High Performance Computer) 구조**: 하나의 차량 안에 아키텍처가 다른 여러 타겟(ARM Cortex-M, Cortex-A, x86 등)이 공존 → 멀티 타겟 크로스 컴파일이 기본값

### 4-2. 통합 빌드의 구조적 난제
- **다수 공급업체(Tier1/Tier2) 코드 통합**: 서로 다른 조직이 만든 컴포넌트를 하나의 빌드 그래프로 묶어야 함 → 인터페이스 계약(예: 코드 생성 기반 인터페이스, ARXML)과 빌드 의존성 관리
- **모놀리식 통합 빌드 vs 컴포넌트별 독립 빌드**: 빌드 시간 vs 통합 검증의 트레이드오프
- **버전/변형(Variant) 관리**: 동일 플랫폼에서 차종/트림별로 다른 빌드 변형(feature flag, 빌드 설정 조합)을 다루는 방법
- **코드 생성 도구 연계**: AUTOSAR RTE 생성기, DBC/ARXML 기반 코드 생성 등이 빌드 그래프의 입력이 되는 구조

### 4-3. 안전/보안/규제 고려사항
- **기능안전(ISO 26262)**: 빌드 산출물의 추적성(traceability) — 어떤 소스가 어떤 바이너리를 만들었는지 증명 가능해야 함
- **사이버보안(ISO/SAE 21434)**: 소프트웨어 공급망 보안, SBOM(Software Bill of Materials) 생성이 빌드 파이프라인의 필수 산출물이 되는 추세
- **재현 가능한 빌드**: 인증/검증 과정에서 "동일 소스로 동일 바이너리 재생성 가능"을 요구받는 경우가 많음

### 4-4. 스케일과 성능
- 코드베이스 규모가 일반 앱보다 훨씬 큼(수백만~수천만 LOC) → 원격 캐싱/원격 실행이 선택이 아닌 필수
- OTA(Over-The-Air) 업데이트를 고려한 빌드 아티팩트 설계 (차분 업데이트를 위한 바이너리 구조 등)

### 4-5. 참고할 만한 산업 표준/이니셔티브 (검색 키워드로 활용)
- SOAFEE (Scalable Open Architecture For Embedded Edge)
- Eclipse SDV 워킹그룹
- COVESA (Connected Vehicle Systems Alliance)
- AUTOSAR 공식 문서

### 4단계 세부 진행안 (2026-10-05 준비)

실습 위치: `practice/week4/` (3주차 Bazel 프로젝트를 확장: 벤더 모듈 추가, 크로스 컴파일 플랫폼 정의)
실행 환경: WSL Bazel 9.2.0 (로컬 중심), 필요한 경우 `.github/workflows/`에 잡을 추가해 CI에서도 확인

4-1 ~ 4-4는 3단계 리뷰(`docs/stage3_cicd_review.md` §3 "SDV 관점 스트레스 테스트")에서 짚었던 "지금 파이프라인이 무너지는 지점"을 하나씩 실제로 고쳐보는 방식으로 진행한다.

- [x] **4-1. 멀티 타겟 크로스 컴파일** (2026-10-05 완료): 개념 — AUTOSAR Classic(ARXML→RTE 생성기, 정적 모놀리식 이미지, MCU) vs Adaptive(POSIX, 서비스 지향 `ara::com`, 독립 프로세스 단위 OTA, HPC), ECU/도메인 컨트롤러/HPC 통합으로 한 차량 빌드가 "MCU용 Classic + HPC용 Adaptive/Linux"를 동시에 만들어야 하는 구조. 실습 — `practice/week4/toolchain/`에 `cc_toolchain_config`(aarch64-linux-gnu-gcc 도구 경로 + 헤더 검색 경로) + `cc_toolchain` + `toolchain()`(exec=x86_64 리눅스, target=aarch64 리눅스) + `aarch64_linux` platform을 직접 정의. `bazel build //:app --platforms=//toolchain:aarch64_linux` → `file`로 ARM aarch64 확인 → 네이티브 실행 시 1단계와 같은 "Exec format error" 재현 → `qemu-aarch64 -L /usr/aarch64-linux-gnu`로 정상 실행까지 확인. (Bazel 9.2.0에서는 `cc_common`/`CcToolchainConfigInfo`/`cc_toolchain`이 더 이상 암묵적 전역이 아니라 `@rules_cc`에서 명시적으로 load해야 한다는 점을 디버깅하며 확인)
- [ ] **4-2. 벤더 코드 통합 & 변형(Variant) 관리**: 개념 — Tier1/Tier2 공급업체 컴포넌트 통합, 인터페이스 계약(ARXML 등). 실습 — bzlmod `local_path_override` 등으로 "가상 벤더" 모듈을 외부 의존성처럼 추가(사전 빌드된 `.a`를 가정, 소스 없이), `config_setting` + `select()`로 차종/리전 변형(예: `REGION_EU` vs `REGION_US`)에 따라 다른 빌드 설정이 적용되는 구조 실습
- [ ] **4-3. 추적성 & SBOM**: 개념 — ISO 26262 추적성(소스→바이너리 증명), ISO/SAE 21434와 SBOM. 실습(가벼움) — `bazel query 'deps(//...)'`로 의존성 목록을 뽑아 간단한 SBOM 초안을 생성하고, 3단계에서 만든 `BUILD_INFO.txt`(커밋 SHA) 구조와 연결해 "이 바이너리에 무엇이 들어갔는지" 증명하는 최소 구성을 정리
- [ ] **4-4. 스케일 & 성능 & OTA**: 개념 중심(실습 보류) — `--remote_cache`/원격 실행(RBE)이 왜 필수가 되는지(3-4에서 쓴 `actions/cache`의 한계: 저장소당 용량 제한, 다운로드 비용), OTA 차분 업데이트를 고려한 아티팩트 설계. 실제 RBE 클러스터 구성은 보류하고 5단계와 연결
- [ ] **4-5. 참고 자료 서베이**: SOAFEE, Eclipse SDV 워킹그룹, COVESA, AUTOSAR 공식 문서를 훑어보고 핵심 키워드만 정리 (실습 없음, 리뷰 때 문서화)

각 항목이 끝날 때마다 간단히 정리하고, 4단계가 모두 끝나면 3단계와 같은 방식으로 리뷰 문서(`docs/stage4_sdv_review.md`)를 작성해 5단계 미니 프로젝트로 연결한다.

---

## 5단계: 실전 미니 프로젝트 (약 1~2주)

배운 것을 통합하는 단계.

1. Bazel로 **서로 다른 아키텍처(x86 + ARM 크로스 컴파일)** 를 타겟팅하는 멀티 타겟 프로젝트 구성
2. 2~3개의 "가상 공급업체 컴포넌트"를 별도 패키지로 만들고 하나의 통합 빌드 그래프로 묶기
3. CI 파이프라인에 원격 캐시를 연결해 빌드 시간 개선을 직접 측정
4. 빌드 산출물에 대한 간단한 SBOM(예: `bazel query`로 의존성 목록 추출) 생성해보기

---

## 진행 상태 체크리스트

- [x] 1단계: 빌드의 본질 이해
- [x] 2단계: 빌드 시스템 도구 실습 (Make/CMake → Bazel)
  - [x] 2-1. Make/CMake 훑기 (practice/week2/01_make, 02_cmake)
  - [x] 2-2. Bazel 심화 (practice/week2/03_bazel) — 원격 실행(RBE)·멀티 언어 지원은 개념만 다룸, 실습 보류
- [x] 3단계: CI/CD와 빌드의 결합 (2026-10-03 완료, practice/week3 + .github/workflows/week3-ci.yml, 리뷰: docs/stage3_cicd_review.md) — 컨테이너 잡·hermetic 툴체인·원격 캐시 서버는 개념만 다룸
- [ ] 4단계: SDV 특화 통합 빌드 고려사항 ← 다음 진행
- [ ] 5단계: 실전 미니 프로젝트
