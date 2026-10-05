#include <stdio.h>
#include "foo.h"

/* 3-2 실습: "내 컴퓨터에서는 되는데 CI에서만 실패하는" 테스트.
 * 기대값을 외부 파일에서 읽는데, 그 파일을 BUILD에 선언하지 않고
 * 로컬(WSL) 절대 경로로 직접 연다. */
//#define EXPECTED_FILE \
  "/mnt/c/Users/inter/Study/sw_build/build_study/practice/week3/testdata/expected.txt"
#define EXPECTED_FILE "testdata/expected.txt"

int main(void) {
  FILE *fp = fopen(EXPECTED_FILE, "r");
  if (fp == NULL) {
    printf("FAIL: cannot open %s\n", EXPECTED_FILE);
    return 1;
  }

  int expected = 0;
  if (fscanf(fp, "%d", &expected) != 1) {
    printf("FAIL: invalid content in %s\n", EXPECTED_FILE);
    fclose(fp);
    return 1;
  }
  fclose(fp);

  int actual = add(3, 4) + OFFSET;
  if (actual != expected) {
    printf("FAIL: expected %d, got %d\n", expected, actual);
    return 1;
  }

  printf("PASS: add(3, 4) + OFFSET == %d\n", expected);
  return 0;
}
