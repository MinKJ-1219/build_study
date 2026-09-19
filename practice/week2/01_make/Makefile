# 2주차 실습: Makefile의 타겟(target) - 의존성(prerequisite) - 레시피(recipe) 구조
# 레시피 줄은 반드시 TAB으로 시작해야 한다 (스페이스면 "missing separator" 에러)

CC := gcc
CFLAGS := -Wall -Wextra -g

# 최종 산출물. main.o, foo.o가 하나라도 바뀌면 다시 링크된다.
app: main.o foo.o
	$(CC) $(CFLAGS) -o app main.o foo.o

# 객체 파일 타겟: 대응하는 .c와 공용 헤더 foo.h가 바뀔 때만 재컴파일된다.
main.o: main.c foo.h
	$(CC) $(CFLAGS) -c main.c

foo.o: foo.c foo.h
	$(CC) $(CFLAGS) -c foo.c

# .PHONY: clean/run은 실제 파일이 아니라 "명령" 이름임을 make에게 알려준다.
.PHONY: clean run
clean:
	rm -f app main.o foo.o

run: app
	./app
