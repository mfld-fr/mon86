//------------------------------------------------------------------------------
// MON86 - Low level routines
//------------------------------------------------------------------------------

#include "mon86-target.h"

// Offsets in globals structure
// Synchronize with mon86-target

#define glob_magic 0x0
#define master_sp  0x2
#define master_ss  0x4
#define slave_sp   0x6
#define slave_ss   0x8
#define slave_run  0xA
#define slave_ret  0xB

// Offsets in stack frame

#define iret_size    0x6

#define stack_ax     2*0x0
#define stack_cx     2*0x1
#define stack_dx     2*0x2
#define stack_bx     2*0x3
#define stack_sp     2*0x4
#define stack_bp     2*0x5
#define stack_si     2*0x6
#define stack_di     2*0x7
#define stack_es     2*0x8
#define stack_ds     2*0x9
#define stack_num    2*0xA
#define stack_ip     2*0xB
#define stack_cs     2*0xC
#define stack_fl     2*0xD

#define stack_size   2*0xE

// Offsets in registers structure
// Synchronize with mon86-target

#define reg_ax     2*0x0
#define reg_cx     2*0x1
#define reg_dx     2*0x2
#define reg_bx     2*0x3
#define reg_sp     2*0x4
#define reg_bp     2*0x5
#define reg_si     2*0x6
#define reg_di     2*0x7
#define reg_es     2*0x8
#define reg_cs     2*0x9
#define reg_ss     2*0xA
#define reg_ds     2*0xB
#define reg_ip     2*0xC
#define reg_fl     2*0xD

#define reg_max    0xE
#define regs_size  2*reg_max

// Offsets in context stucture
// Synchronize with mon86-common

#define context_off  0x0
#define context_seg  0x2
#define context_len  0x4
#define context_val  0x6

	.code16
	.text

//------------------------------------------------------------------------------

	.extern main

// Program entry

	.global entry

entry:

	push  %ax
	push  %cx
	call  entry_1  // self-call to push IP

entry_1:

	// Compute offset & segment displacement

	pop   %ax
	sub   $entry_1,%ax
	mov   $4,%cl
	shr   %cl,%ax

	// Realign segment and offset

	mov   %cs,%cx
	add   %cx,%ax
	push  %ax
	mov   $entry_2,%ax
	push  %ax
	retf  // self-return to pop CS:IP

entry_2:

	// Small memory model (DS=ES=SS)
	// and no data segment used here
	// so stay on the stack segment

	mov    %ss,%ax
	mov    %ax,%ds
	mov    %ax,%es
	pop    %cx
	pop    %ax
	jmp    main

//------------------------------------------------------------------------------

// Read from memory to context

	.global mem_read

mem_read:

	push   %bp
	mov    %sp,%bp
	push   %ax
	push   %bx
	push   %si
	mov    4(%bp),%bx  // arg1 = context *
	mov    context_off(%bx),%si
	push   %ds
	mov    context_seg(%bx),%ds
	lodsb
	pop    %ds
	mov    $0,%ah
	mov    %ax,context_val(%bx)
	mov    %si,context_off(%bx)  // context.off++
	pop    %si
	pop    %bx
	pop    %ax
	pop    %bp
	ret

// Write from context to memory

	.global mem_write

mem_write:

	push   %bp
	mov    %sp,%bp
	push   %ax
	push   %bx
	push   %di
	mov    4(%bp),%bx  // arg1 = context *
	mov    context_off(%bx),%di
	mov    context_val(%bx),%ax
	push   %es
	mov    context_seg(%bx),%es
	stosb
	pop    %es
	mov    %di,context_off(%bx)  // context.off++
	pop    %di
	pop    %bx
	pop    %ax
	pop    %bp
	ret

//------------------------------------------------------------------------------

// Setup registers with safe values

	.global reg_setup

reg_setup:

	push   %bp
	mov    %sp,%bp
	push   %ax
	push   %bx

	mov    4(%bp),%bx  // arg1 = regs *

	xor    %ax,%ax
	mov    %ax,reg_ax(%bx)
	mov    %ax,reg_cx(%bx)
	mov    %ax,reg_dx(%bx)
	mov    %ax,reg_bx(%bx)
	mov    %ax,reg_sp(%bx)
	mov    %ax,reg_bp(%bx)
	mov    %ax,reg_si(%bx)
	mov    %ax,reg_di(%bx)

	mov    %es,reg_es(%bx)
	mov    %cs,reg_cs(%bx)
	mov    %ss,reg_ss(%bx)
	mov    %ds,reg_ds(%bx)

	mov    $task_stub,%ax
	mov    %ax,reg_ip(%bx)

	pushf
	pop    %ax
	mov    %ax,reg_fl(%bx)

	pop    %bx
	pop    %ax
	pop    %bp
	ret

//------------------------------------------------------------------------------

// Call far procedure

	.global proc_call

proc_call:
	push   %bp
	mov    %sp,%bp
	push   %ax
	push   %bx
	push   %cx
	push   %dx
	push   %si
	push   %di

	mov    4(%bp),%bx  // arg1 = context *

	push   %bp

	// Push return far address

	push   %cs
	mov    $proc_ret,%ax
	push   %ax

	// Push call far address

	mov    context_seg(%bx),%ax
	push   %ax
	mov    context_off(%bx),%ax
	push   %ax

	// Load registers through the stack
	// Excluding FL - Including BP

	mov    6(%bp),%si  // arg2 = regs *
	mov    $reg_max,%cx

proc_push:

	lodsw
	push   %ax
	loop   proc_push

	add    $4,%sp  // skip FL and IP
	pop    %ds
	add    $4,%sp  // skip CS and SS
	pop    %es
	pop    %di
	pop    %si
	pop    %bp
	add    $2,%sp  // skip SP
	pop    %bx
	pop    %dx
	pop    %cx
	pop    %ax

	// Jump to procedure

	retf

proc_ret:

	pop    %bp

	// Save registers through the stack
	// Including FL - Excluding BP

	pushf
	sub    $2,%sp  // skip IP
	push   %ds
	sub    $4,%sp  // skip CS and SS
	push   %es
	push   %di
	push   %si
	sub    $4,%sp  // skip SP and BP
	push   %bx
	push   %dx
	push   %cx
	push   %ax

	mov    %ss,%ax  // DS=ES=SS
	mov    %ax,%ds
	mov    %ax,%es

	mov    6(%bp),%di  // arg2 = regs *
	mov    $reg_max,%cx

proc_pop:

	pop    %ax
	stosw
	loop   proc_pop

	pop    %di
	pop    %si
	pop    %dx
	pop    %cx
	pop    %bx
	pop    %ax
	pop    %bp
	ret

//------------------------------------------------------------------------------

// INT 01h - Trace

int_trace:

	call   int_hand
	.word  vect_trace

// INT 03h - Break

int_break:

	call   int_hand
	.word  vect_break

// Slave exit on IRET
// Push IRET frame to simulate INT FFh interrupt
// To reuse context switch of real interrupt

slave_exit:

	sub    iret_size,%sp  // space for IRET frame

	push   %bp
	mov    %sp,%bp
	push   %ax

	mov    $task_stub,%ax
	mov    %ax,2(%bp)
	mov    %cs,4(%bp)
	pushf
	pop    %ax
	mov    %ax,6(%bp)

	pop    %ax
	pop    %bp

	call   int_hand
	.word  vect_global

// Interrupt common handler

int_hand:

	// Enable interrupt

	sti

	// Save registers on stack

	push   %ds
	push   %es

#ifdef MON86_186
	pusha
#else
	push   %ax
	push   %cx
	push   %dx
	push   %bx
	sub    $2,%sp  // skip SP
	push   %bp
	push   %si
	push   %di
#endif

	// Retrieve globals * to DS:BX
	// From fixed & safe location
	// Actually the INT FFh vector

	xor    %ax,%ax
	mov    %ax,%ds
	lds    vect_global*4,%bx

	// Switch to master only if slave is running

	mov    slave_run(%bx),%al
	or     %al,%al
	jnz    master_stack

	// Otherwise ignore the interrupt

	jmp    int_ret

	// Switch to master stack
	// Assume DS:BX = globals *

master_stack:

	movb   $0,slave_run(%bx)

	mov    %sp,slave_sp(%bx)
	mov    %ss,slave_ss(%bx)

	// Note: no use of automatic CLI

	cli
	mov    master_sp(%bx),%sp
	mov    master_ss(%bx),%ss
	sti

	jmp    int_ret

	// Switch to slave stack
	// Assume DS:BX = globals *

slave_stack:

	movb   $1,slave_run(%bx)

	mov    %sp,master_sp(%bx)
	mov    %ss,master_ss(%bx)

	// Note: no use of automatic CLI

	cli
	mov    slave_sp(%bx),%sp
	mov    slave_ss(%bx),%ss
	sti

	//jmp    int_ret

// Return from interrupt

int_ret:

	// Restore registers from stack

#ifdef MON86_186
	popa
#else
	pop    %di
	pop    %si
	pop    %bp
	add    $2,%sp  // skip SP
	pop    %bx
	pop    %dx
	pop    %cx
	pop    %ax
#endif

	pop    %es
	pop    %ds

	add    $2,%sp  // skip int_num *

	iret

//------------------------------------------------------------------------------

// Task stub

task_stub:

	iret

// Execute slave task
// arg1 : globals *
// arg2 : regs *

	.global task_exec

task_exec:

	push   %bp
	mov    %sp,%bp
	push   %bx
	push   %cx
	push   %dx
	push   %si
	push   %di

	// Allocate space for slave frame

	mov    6(%bp),%si  // arg2 = regs *
	mov    reg_sp(%si),%di
	mov    reg_ss(%si),%dx
	sub    $stack_size,%di

	// Option for slave exit frame

	mov    4(%bp),%bx  // arg1 = globals *

	testb  $1,slave_ret(%bx)
	jz     1f
	sub    $iret_size,%di

	// Copy structure regs to slave frame

1:	push   %es
	mov    %dx,%es
	push   %di

	// One by one to allow different offsets
	// Order of the stack frame
	// First registers in PUSHA / POPA order

	push   %si
	add    $14,%si
	mov    $8,%cx
1:	std
	lodsw
	cld
	stosw
	loop   1b
	pop    %si

	mov    reg_es(%si),%ax
	stosw
	mov    reg_ds(%si),%ax
	stosw

	add    $2,%di  // skip int_num *

	mov    reg_ip(%si),%ax
	stosw
	mov    reg_cs(%si),%ax
	stosw
	mov    reg_fl(%si),%ax
	stosw

	// Option for slave exit frame

	testb  $1,slave_ret(%bx)
	jz     1f

	mov    $slave_exit,%ax
	stosw
	mov    %cs,%ax
	stosw
	pushf
	pop    %ax
	stosw

	movb   $0,slave_ret(%bx)

1:	pop    %di
	pop    %es

	// Update globals from regs

	mov    %di,slave_sp(%bx)
	mov    %dx,slave_ss(%bx)

	// Push the master back frame

	pushf
	push   %cs
	mov    $master_back,%ax
	push   %ax

	// Push the master frame

	sub    $2,%sp  // skip int_num *

	push   %ds
	push   %es

#ifdef MON86_186
	pusha
#else
	push   %ax
	push   %cx
	push   %dx
	push   %bx
	sub    $2,%sp  // skip SP
	push   %bp
	push   %si
	push   %di
#endif

	// Switch to slave

	jmp    slave_stack

	// Back from slave
	// Assume DS:BX = globals *

master_back:

	mov    %si,%di  // regs *

	mov    slave_sp(%bx),%si  // BX = globals *
	mov    slave_ss(%bx),%dx

	// Copy slave frame to structure regs

	push   %ds
	mov    %dx,%ds
	push   %di

	// One by one to allow different offsets
	// Order of the registers structure
	// First registers in PUSHA / POPA order

	push   %si
	add    $14,%si
	mov    $8,%cx
1:	std
	lodsw
	cld
	stosw
	loop 1b
	pop    %si

	mov    stack_es(%si),%ax
	stosw
	mov    stack_cs(%si),%ax
	stosw
	add    $2,%di  // skip SS
	mov    stack_ds(%si),%ax
	stosw

	mov    stack_ip(%si),%ax
	stosw
	mov    stack_fl(%si),%ax
	stosw

	// Will return the interrupt number to caller

	push   %bx
	mov    stack_num(%si),%bx  // int_num *
	mov    %cs:(%bx),%ax
	pop    %bx

	pop    %di
	pop    %ds

	add    $stack_size,%si  // release slave frame

	mov    %si,reg_sp(%di)
	mov    %dx,reg_ss(%di)

	// Rearm slave exit frame option

	cmp    $0xFF,%al
	jne    1f
	movb   $1,slave_ret(%bx)

	// Back to caller

1:	pop    %di
	pop    %si
	pop    %dx
	pop    %cx
	pop    %bx
	pop    %bp
	ret

//------------------------------------------------------------------------------

// Interrupt setup

	.global int_setup

int_setup:
	push   %bp
	mov    %sp,%bp
	push   %ax
	push   %bx
	push   %dx

	mov    4(%bp),%dx  // arg1 = globals *

	push   %ds
	xor    %ax,%ax
	mov    %ax,%ds

	mov    $vect_trace*4,%bx  // trace interrupt vector
	mov    $int_trace,%ax
	cli
	mov    %ax,(%bx)
	mov    %cs,2(%bx)
	sti

	mov    $vect_break*4,%bx  // break interrupt vector
	mov    $int_break,%ax
	cli
	mov    %ax,(%bx)
	mov    %cs,2(%bx)
	sti

	mov    $vect_global*4,%bx  // pointer to globals
	cli
	mov    %dx,(%bx)
	mov    %es,2(%bx)
	sti

	pop    %ds

	pop    %dx
	pop    %bx
	pop    %ax
	pop    %bp
	ret

//------------------------------------------------------------------------------
