# 2주차 실습: CMake는 "Makefile을 생성하는 빌드 스크립트"라는 점을 확인한다.
# 즉, CMakeLists.txt를 작성하면 CMake가 플랫폼에 맞는 Makefile(or 다른 빌드 시스템)을 만들어준다.

cmake_minimum_required(VERSION 3.10)
project(week2_cmake_demo C)

# foo를 별도 라이브러리 타겟으로 분리 (Part A의 foo.o, Part C의 cc_library :foo 와 대응)
add_library(foo foo.c)
# foo.h를 foo 자신뿐 아니라 foo에 링크하는 쪽(app)도 include할 수 있어야 하므로 PUBLIC
target_include_directories(foo PUBLIC .)

add_executable(app main.c)
# app이 foo에 링크된다는 사실 자체는 app을 다시 링크하는 다른 타겟에 전파할 필요 없으므로 PRIVATE
target_link_libraries(app PRIVATE foo)
