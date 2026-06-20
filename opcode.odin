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

Value :: union {
	Register,
	u8,
	u16
}

ControlInstruction :: struct {}
JumpInstruction :: struct {}
LoadInstruction :: struct {
	destination: Value,
	source: Value,
}
ArithmeticInstruction :: struct {}
BitShiftInstruction :: struct {}

Instruction :: struct {
	op: Opcode,
	type: union {
		ControlInstruction,
		LoadInstruction,
		JumpInstruction,
		ArithmeticInstruction,
		BitShiftInstruction
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
