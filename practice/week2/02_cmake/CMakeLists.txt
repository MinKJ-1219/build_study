# 2주차 실습: CMake는 "Makefile을 생성하는 빌드 스크립트"라는 점을 확인한다.
# 즉, CMakeLists.txt를 작성하면 CMake가 플랫폼에 맞는 Makefile(or 다른 빌드 시스템)을 만들어준다.

cmake_minimum_required(VERSION 3.10)
project(week2_cmake_demo C)

add_executable(app main.c foo.c)
