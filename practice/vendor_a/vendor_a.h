#ifndef VENDOR_A_H
#define VENDOR_A_H

/* 4-2 실습: Tier1 공급업체 "vendor_a"가 우리에게 넘겨주는 유일한 계약(contract).
 * 실제 구현(.c)은 받지 못하고, 이 헤더 + 사전 빌드된 libvendor_a.a만 받는다고 가정한다. */
const char *vendor_a_greet(void);

#endif
