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

.PHONY : all clean

all: $(EXE)

mon86-common.o: ../mon86-common.c
	$(CC) $(CFLAGS) -o $@ -c $<

$(EXE): $(OBJS)
	$(LD) $(LDFLAGS) -M -o $(EXE) $(OBJS) > mon86.map

clean:
	rm -f $(EXE) $(OBJS) mon86.map
