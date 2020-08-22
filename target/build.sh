#!/bin/bash

# Build binaries for target

# Second stage monitor

ia16-elf-gcc -c -o mon86-common.o -I.. ../mon86-common.c
ia16-elf-gcc -c -o mon86-target.o -I.. mon86-target.c

ia16-elf-gcc -E -o mon86-low.s mon86-low.S
ia16-elf-gcc -E -o mon86-arch.s mon86-arch.S

ia16-elf-as -o mon86-low.o mon86-low.s
ia16-elf-as -o mon86-arch.o mon86-arch.s

ia16-elf-ld -M -T raw.ld -o mon86.bin mon86-low.o mon86-arch.o mon86-common.o mon86-target.o > mon86.map
