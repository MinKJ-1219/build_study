#include "undeclared.h"

int hermetic_add(int a, int b) {
    return a + b + UNDECLARED_OFFSET;
}
