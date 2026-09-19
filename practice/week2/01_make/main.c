#include <stdio.h>
#include "foo.h"

int main(void) {
    int result = add(3, 4) + OFFSET;
    printf("result = %d\n", result);
    return 0;
}
