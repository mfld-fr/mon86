# Makefile for target

CC = ia16-elf-gcc

AS = ia16-elf-as

LD = ia16-elf-ld
LDFLAGS = -T raw.ld

EXE = mon86.bin

OBJS= \
  mon86-low.o \
  mon86-arch.o \
  mon86-common.o \
  mon86-target.o \
  # end of list

.PHONY : all clean test

all: $(EXE)

mon86-common.o: ../mon86-common.c
	$(CC) $(CFLAGS) -o $@ -c $<

$(EXE): $(OBJS)
	$(LD) $(LDFLAGS) -M -o $(EXE) $(OBJS) > mon86.map

clean:
	rm -f $(EXE) $(OBJS) mon86.map

test: test-emu

test-emu:
	../../emu86/emu86 -w 0x80000 -f ../../img/ADVTECH1.BIN -w 0xf8100 -f mon86.bin &
	sleep 10
	../../emu86/pcat -t 1000 -d 1 `cat emu86.pts` < ../test-mon86-in.txt > test-emu-out.txt
	diff ../test-mon86-ref.txt test-emu-out.txt

