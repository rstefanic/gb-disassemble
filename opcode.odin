package main

Register :: enum {
	A,
	B,
	C,
	BC,
	D,
	E,
	DE,
	H,
	L,
	HL,
	SP,
	PC
}

Flag :: enum {
	None,
	C,
	H,
	N,
	Z,
} 

Value :: struct {
	location: union {
		Register,
		u8,        //  8 bit immediate value
		u16,       // 16 bit immediate value
	},
	dereference_in_memory: bool,
	postfix_operator: enum {
		None,
		Increment,
		Decrement
	}
}

Steps :: distinct u8
Location :: distinct u16

// Instruction Types
Control :: struct {}
ConditionalJump :: struct {
	flag: Flag,
	set: bool,
	place: union {
		Steps,
		Location
	}
}
UnconditionalJump :: struct {
	place: union {
		Steps,
		Location
	}
}
Load :: struct {
	destination: Value,
	source: Value,
}
UnaryArithmetic :: struct {
	destination: Value
}
BinaryArithmetic :: struct {
	destination: Value,
	source: Value,
}
ConditionalReturn :: struct {
	// TODO: See if `ConditionalReturn` can't be replaced with
	// Conditional Jump since that's effectively what it is.
	flag: Flag,
	set: bool
}
StackControl :: struct {
	destination: Value
}
Pop :: struct {
	destination: Value
}
BitShift :: struct {}

Instruction :: struct {
	op: Opcode,
	type: union {
		Control,
		Load,
		UnconditionalJump,
		ConditionalJump,
		UnaryArithmetic,
		BinaryArithmetic,
		ConditionalReturn,
		StackControl,
		BitShift
	}
}

Opcode :: enum u8 {
	// 8 bit instructions
	NOP,
	LD,
	INC,
	DEC,
	RLCA,
	ADD,
	RRCA,
	STOP,
	RLA,
	JR,
	RRA,
	DAA,
	CPL,
	SCF,
	CCF,
	HALT,
	ADC,
	SUB,
	SBC,
	AND,
	XOR,
	OR,
	CP,
	RET,
	POP,
	JP,
	CALL,
	PUSH,
	RST,
	PREFIX,
	RETI,
	DI,
	EI,

	// 16 bit instructions
	RLC,
	RRC,
	RL,
	RR,
	SLA,
	SRA,
	SWAP,
	SRL,
	BIT,
	RES,
	SET
}
