package main 

import "core:fmt"
import "core:os"
import "core:mem"
import "core:testing"

main :: proc () {
	// Make sure we have a file to parse
	if len(os.args) < 2 {
		fmt.println("ROM path required.")
		return
	}

	// Allocate memory for the program
	arena_backing_mem:= make([]byte, 1*mem.Megabyte)
	defer delete(arena_backing_mem)
	arena: mem.Arena
	mem.arena_init(&arena, arena_backing_mem)
	arena_alloc := mem.arena_allocator(&arena)

	rom_path := os.args[1]
	binary, err := binary_read_rom(rom_path, arena_alloc)
	switch err {
		case nil:
		case .Not_Exist:
			fmt.println("File does not exist.")
		case:
			fmt.println("Unexpected error occurred while opening ROM.")
	}

	instructions := make([dynamic]Instruction, 0, 2048);
	defer delete(instructions)
	disassemble_err := disassemble(binary, &instructions)
	if disassemble_err != DisassembleError.None {
		fmt.println(disassemble_err)
		return
	}

	for ins in instructions {
		fmt.println(ins)
	}
}

DisassembleError :: enum {
	None,
	UnexpectedByte,
	UnexpectedEOF
}

disassemble :: proc (binary: ^Binary, instructions: ^[dynamic]Instruction) -> DisassembleError {
	for i := 0; i < len(instructions); i += 1 {
		b, err := binary_peek(binary) 
		if err == .EOF {
			return nil
		}

		// Get a reference to the value we're modifying.
		instruction := &instructions[i]

		switch b {
		case 0x00:
			parse_nop(binary, instruction) or_return
		case 0x01:
			parse_ld_bc_imm16(binary, instruction) or_return
		case 0x02:
		case:
			return DisassembleError.UnexpectedByte
		}
	}

	return nil
}

parse_nop :: proc (binary: ^Binary, instruction: ^Instruction) -> DisassembleError {
	b, err := binary_next(binary)
	if err != nil {
		return .UnexpectedEOF
	}

	instruction.op = Opcode.NOP
	return nil
}

@(test)
test_parse_nop :: proc(t: ^testing.T) {
	bin := Binary {
		buf = []byte{0x00},
		allocator = context.allocator
	}

	instructions := make([dynamic]Instruction, 1);
	defer delete(instructions)
	disassemble(&bin, &instructions)

	testing.expect_value(t, instructions[0], Instruction{op = Opcode.NOP})
}

parse_ld_bc_imm16 :: proc (binary: ^Binary, instruction: ^Instruction) -> DisassembleError {
	op_byte, err := binary_next(binary)
	if err != nil {
		return .UnexpectedEOF
	}

	hi, hi_err := binary_next(binary)
	if hi_err != nil {
		return .UnexpectedEOF
	}

	lo, lo_err := binary_next(binary)
	if lo_err != nil {
		return .UnexpectedEOF
	}

	result: u16 = (cast(u16)(hi << 8)) | (cast(u16)lo)
	instruction.op = Opcode.LD
	instruction.type = LoadInstruction {
		destination = .BC,
		source = result
	}

	return nil
}

@(test)
test_parse_ld_bc_imm16 :: proc(t: ^testing.T) {
	bin := Binary {
		buf = []byte{0x01, 0x00, 0x01},
		allocator = context.allocator
	}

	instructions := make([dynamic]Instruction, 1);
	defer delete(instructions)
	disassemble(&bin, &instructions)

	testing.expect_value(t, instructions[0], Instruction{
		op = Opcode.LD,
		type = LoadInstruction {
			source = u16(0x01),
			destination = Register.BC
		}
	})
}
