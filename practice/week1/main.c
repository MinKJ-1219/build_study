#include <stdio.h>
#include "foo.h"

int main(void) {
    int result = add(3, 4) + OFFSET; // OFFSET을 사용하여 결과에 100을 더함
    printf("result = %d\n", result);
    printf("Built at %s %s\n", __DATE__, __TIME__);
    return 0;
}
