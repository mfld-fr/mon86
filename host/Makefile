# Makefile for host stub and tool

CFLAGS = -g -D MON86_HOST

HOST = mon86-host
STUB = mon86-stub

.PHONY: all clean test

all: $(STUB) $(HOST)

mon86-common.o: ../mon86-common.c
	$(CC) $(CFLAGS) -o $@ -c $<

$(STUB).o: ../target/mon86-target.c
	$(CC) $(CFLAGS) -D HOST_STUB -o $@ -c $<

$(STUB): mon86-common.o $(STUB).o

$(HOST): mon86-common.o $(HOST).o

clean:
	rm -f *.o $(STUB) $(HOST)

test: stub.test

stub.test:
	./$(STUB) < ../test-mon86-in.txt > test-stub-out.txt
	diff test-stub-ref.txt test-stub-out.txt
