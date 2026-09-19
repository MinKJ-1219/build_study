#include "foo.h"

int add(int a, int b) {
    // 일부러 로직을 살짝 바꿔서 증분 빌드 효과를 눈으로 확인
    int sum = a + b;
    int increment = 1; // 증분 빌드 효과를 확인하기 위해 추가된 코드
    return sum;
}
