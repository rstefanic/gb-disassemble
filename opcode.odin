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

Value :: union {
	Register,
	u8,
	u16
}

// Instruction Types
Control :: struct {}
ConditionalJump :: struct {
	steps: u8,
	flag: Flag,
	set: bool
}
UnconditionalJump :: struct {
	steps: u8
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
