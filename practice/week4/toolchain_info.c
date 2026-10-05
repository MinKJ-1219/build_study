#include <stdio.h>

/* 이 바이너리를 "실제로 컴파일한 툴체인"이 무엇인지 출력한다.
 * 로컬(WSL)과 CI 러너에서 각각 실행해 결과를 비교하는 것이 목적. */
int main(void) {
  printf("compiler : gcc %s\n", __VERSION__);
  printf("C std    : %ld\n", __STDC_VERSION__);
  /* Bazel은 재현성을 위해 __DATE__/__TIME__을 "redacted"로 덮어쓴다 */
  printf("built at : %s %s\n", __DATE__, __TIME__);
  return 0;
}
