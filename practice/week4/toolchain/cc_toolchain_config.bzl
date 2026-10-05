# 4-1 실습: aarch64 크로스 컴파일을 위한 최소 C++ 툴체인 설정.
#
# Bazel 공식 C++ 툴체인 튜토리얼(ccp-toolchain-config)의 최소 구성을 그대로 따르되,
# 컴파일러만 clang -> aarch64-linux-gnu-gcc(Ubuntu의 gcc-aarch64-linux-gnu 패키지가 설치한
# 크로스 gcc)로 바꿨다. tool_paths만 채우면 Bazel이 레거시 방식으로 컴파일/링크 액션을
# 자동 구성해준다 (별도 action_config/flag_set 없이도 "컴파일되는" 최소 툴체인이 된다).
#
# cxx_builtin_include_directories는 aarch64-linux-gnu-gcc -E -Wp,-v -xc /dev/null 로
# 확인한 이 크로스 컴파일러의 실제 헤더 검색 경로다. Bazel 샌드박스가 이 경로 밖의
# 헤더 include를 거부하기 때문에, 실제 컴파일러가 보는 경로와 반드시 일치해야 한다.

load(
    "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
    "tool_path",
)
# Bazel 공식 튜토리얼 문서는 cc_common / CcToolchainConfigInfo를 암묵적 전역으로 쓰지만,
# 이 Bazel 버전(9.2.0)에서는 C++ 규칙이 rules_cc(Starlark)로 완전히 이전되면서
# 둘 다 rules_cc에서 명시적으로 load해야 한다.
load(
    "@rules_cc//cc/toolchains:cc_toolchain_config_info.bzl",
    "CcToolchainConfigInfo",
)
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

def _impl(ctx):
    tool_paths = [
        tool_path(name = "gcc", path = "/usr/bin/aarch64-linux-gnu-gcc"),
        tool_path(name = "ld", path = "/usr/bin/aarch64-linux-gnu-ld"),
        tool_path(name = "ar", path = "/usr/bin/aarch64-linux-gnu-ar"),
        tool_path(name = "cpp", path = "/usr/bin/aarch64-linux-gnu-cpp"),
        tool_path(name = "gcov", path = "/usr/bin/aarch64-linux-gnu-gcov"),
        tool_path(name = "nm", path = "/usr/bin/aarch64-linux-gnu-nm"),
        tool_path(name = "objdump", path = "/usr/bin/aarch64-linux-gnu-objdump"),
        tool_path(name = "strip", path = "/usr/bin/aarch64-linux-gnu-strip"),
    ]

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = "aarch64-toolchain",
        host_system_name = "local",
        target_system_name = "aarch64-linux-gnu",
        target_cpu = "aarch64",
        target_libc = "glibc",
        compiler = "gcc",
        abi_version = "unknown",
        abi_libc_version = "unknown",
        tool_paths = tool_paths,
        cxx_builtin_include_directories = [
            "/usr/lib/gcc-cross/aarch64-linux-gnu/13/include",
            "/usr/aarch64-linux-gnu/include",
            "/usr/include",
        ],
    )

cc_toolchain_config = rule(
    implementation = _impl,
    attrs = {},
    provides = [CcToolchainConfigInfo],
)
