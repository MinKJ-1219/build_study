#include "region.h"

/* 4-2 실습: US 변형(variant) 구현. --define=region=us일 때 select()가 고른다. */
const char *region_name(void) {
    return "US (imperial, 다른 규제 프로필)";
}
