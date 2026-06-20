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
	UnexpectedByte
}

Error :: union {
	DisassembleError,
	BinaryError
}

disassemble :: proc (binary: ^Binary, instructions: ^[dynamic]Instruction) -> Error {
	for i := 0; i < len(instructions); i += 1 {
		b := binary_peek(binary) or_return

		// Get a reference to the value we're modifying.
		instruction := &instructions[i]

		switch b {
		case 0x00:
			parse_nop(binary, instruction) or_return
		case 0x01:
			parse_ld_bc_imm16(binary, instruction) or_return
		case 0x02:
			parse_ld_bc_a(binary, instruction) or_return
		case 0x03:
			parse_inc_bc(binary, instruction) or_return
		case 0x04:
			parse_inc_b(binary, instruction) or_return
		case 0x05:
			parse_dec_b(binary, instruction) or_return
		case 0x06:
			parse_ld_b_imm8(binary, instruction) or_return
		case 0x07:
			parse_rlca(binary, instruction) or_return
		case 0x08:
			parse_ld_addr16_sp(binary, instruction) or_return
		case 0x09:
			parse_add_hl_bc(binary, instruction) or_return
		case 0x0A:
			parse_ld_a_bc(binary, instruction) or_return
		case 0x0B:
			parse_dec_bc(binary, instruction) or_return
		case:
			return DisassembleError.UnexpectedByte
		}
	}

	return nil
}

parse_nop :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	b := binary_next(binary) or_return
	instruction.op = Opcode.NOP
	return nil
}

// Helper function for setting up instruction parsing tests.
test_instruction_parse :: proc(t: ^testing.T, buf: []byte, expected_instruction: Instruction) {
	bin := Binary {
		buf = buf,
		allocator = context.allocator
	}

	instructions := make([dynamic]Instruction, 1);
	defer delete(instructions)
	disassemble(&bin, &instructions)

	testing.expect_value(t, instructions[0], expected_instruction)
}

@(test)
test_parse_nop :: proc(t: ^testing.T) {
	expected := Instruction{op = Opcode.NOP}
	test_instruction_parse(t, []byte{0x00}, expected)
}

parse_ld_bc_imm16 :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	lo := binary_next(binary) or_return
	hi := binary_next(binary) or_return

	result: u16 = (cast(u16)hi << 8) | (cast(u16)lo)
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = .BC,
		source = result
	}

	return nil
}

@(test)
test_parse_ld_bc_imm16 :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			source = u16(0x01),
			destination = Register.BC
		}
	}
	test_instruction_parse(t, []byte{0x01, 0x01, 0x00}, expected)
}

parse_ld_bc_a :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Register.BC,
		source = Register.A
	}

	return nil
}

@(test)
test_parse_ld_bc_a :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			source = Register.A,
			destination = Register.BC
		}
	}
	test_instruction_parse(t, []byte{0x02}, expected)
}

parse_inc_bc :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.INC
	instruction.type = UnaryArithmetic {
		destination = Register.BC,
	}

	return nil
}

@(test)
test_parse_inc_bc :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.INC,
		type = UnaryArithmetic {
			destination = Register.BC
		}
	}
	test_instruction_parse(t, []byte{0x03}, expected)
}

parse_inc_b :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.INC
	instruction.type = UnaryArithmetic {
		destination = Register.B,
	}

	return nil
}

@(test)
test_parse_inc_b :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.INC,
		type = UnaryArithmetic {
			destination = Register.B
		}
	}
	test_instruction_parse(t, []byte{0x04}, expected)
}

parse_dec_b :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.DEC
	instruction.type = UnaryArithmetic {
		destination = Register.B,
	}

	return nil
}

@(test)
test_parse_dec_b :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.DEC,
		type = UnaryArithmetic {
			destination = Register.B
		}
	}
	test_instruction_parse(t, []byte{0x05}, expected)
}

parse_ld_b_imm8 :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	imm8 := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Register.B,
		source = u8(imm8)
	}

	return nil
}

@(test)
test_parse_ld_b_imm8 :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Register.B,
			source = u8(0x10)
		}
	}
	test_instruction_parse(t, []byte{0x06, 0x10}, expected)
}

parse_rlca :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.RLCA
	return nil
}

@(test)
test_parse_rlca :: proc(t: ^testing.T) {
	expected := Instruction { op = Opcode.RLCA }
	test_instruction_parse(t, []byte{0x07}, expected)
}

parse_ld_addr16_sp :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	lo := binary_next(binary) or_return
	hi := binary_next(binary) or_return
	address: u16 = (cast(u16)hi << 8) | (cast(u16)lo)

	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Register.SP,
		source = address
	}
	return nil
}

@(test)
test_parse_ld_addr16_sp :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Register.SP,
			source = 0x1234
		}
	}
	test_instruction_parse(t, []byte{0x08, 0x34, 0x12}, expected) // little endian 0x1234
}

parse_add_hl_bc :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.ADD
	instruction.type = BinaryArithmetic {
		destination = Register.HL,
		source = Register.BC
	}
	return nil
}

@(test)
test_parse_add_hl_bc :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.ADD,
		type = BinaryArithmetic {
			destination = Register.HL,
			source = Register.BC
		}
	}
	test_instruction_parse(t, []byte{0x09}, expected)
}

parse_ld_a_bc :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Register.A,
		source = Register.BC
	}
	return nil
}

@(test)
test_parse_ld_a_bc:: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Register.A,
			source = Register.BC
		}
	}
	test_instruction_parse(t, []byte{0x0A}, expected)
}


parse_dec_bc :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.DEC
	instruction.type = UnaryArithmetic {
		destination = Register.BC
	}
	return nil
}

@(test)
test_parse_dec_bc:: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.DEC,
		type = UnaryArithmetic {
			destination = Register.BC
		}
	}
	test_instruction_parse(t, []byte{0x0B}, expected)
}

