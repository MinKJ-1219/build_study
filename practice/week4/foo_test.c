#include <stdio.h>
#include "foo.h"

/* 실패한 검사 개수. 0이면 main이 0을 반환해 bazel test가 PASS로 판정한다. */
static int failures = 0;

static void expect_eq(int actual, int expected, const char *label) {
  if (actual != expected) {
    printf("FAIL: %s (expected %d, got %d)\n", label, expected, actual);
    failures++;
  } else {
    printf("PASS: %s\n", label);
  }
}

int main(void) {
  expect_eq(add(3, 4), 7, "add(3, 4)");
  expect_eq(add(-1, 1), 0, "add(-1, 1)");
  expect_eq(add(3, 4) + OFFSET, 107, "add(3, 4) + OFFSET");

  return failures == 0 ? 0 : 1;
}
