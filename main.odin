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
		// 0x00 - 0x0F
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
		case 0x0C:
			parse_inc_c(binary, instruction) or_return
		case 0x0D:
			parse_dec_c(binary, instruction) or_return
		case 0x0E:
			parse_ld_c_imm8(binary, instruction) or_return
		case 0x0F:
			parse_rrca(binary, instruction) or_return

		// 0x10 - 0x1F
		case 0x10:
			parse_stop(binary, instruction) or_return
		case 0x11:
			parse_ld_de_imm16(binary, instruction) or_return
		case 0x12:
			parse_ld_de_a(binary, instruction) or_return
		case 0x13:
			parse_inc_de(binary, instruction) or_return
		case 0x14:
			parse_inc_d(binary, instruction) or_return
		case 0x15:
			parse_dec_d(binary, instruction) or_return
		case 0x16:
			parse_ld_d_imm8(binary, instruction) or_return
		case 0x17:
			parse_rla(binary, instruction) or_return
		case 0x18:
			parse_jr_s8(binary, instruction) or_return
		case 0x19:
			parse_add_hl_de(binary, instruction) or_return
		case 0x1A:
			parse_ld_a_de(binary, instruction) or_return
		case 0x1B:
			parse_dec_de(binary, instruction) or_return
		case 0x1C:
			parse_inc_e(binary, instruction) or_return
		case 0x1D:
			parse_dec_e(binary, instruction) or_return
		case 0x1E:
			parse_ld_e_imm8(binary, instruction) or_return
		case 0x1F:
			parse_rra(binary, instruction) or_return

		// 0x20 - 0x2F
		case 0x20:
			parse_jr_nz_s8(binary, instruction) or_return
		case 0x21:
			parse_ld_hl_inc_imm16(binary, instruction) or_return
		case 0x22:
			parse_ld_hl_a(binary, instruction) or_return
		case 0x23:
			parse_inc_hl(binary, instruction) or_return
		case 0x24:
			parse_inc_h(binary, instruction) or_return
		case 0x25:
			parse_dec_h(binary, instruction) or_return
		case 0x26:
			parse_ld_h_imm8(binary, instruction) or_return
		case 0x27:
			parse_daa(binary, instruction) or_return
		case 0x28:
			parse_jr_z_s8(binary, instruction) or_return
		case 0x29:
			parse_add_hl_hl(binary, instruction) or_return
		case 0x2A:
			parse_ld_a_hl_inc(binary, instruction) or_return
		case 0x2B:
			parse_dec_hl(binary, instruction) or_return
		case 0x2C:
			parse_inc_l(binary, instruction) or_return
		case 0x2D:
			parse_dec_l(binary, instruction) or_return
		case 0x2E:
			parse_ld_l_imm8(binary, instruction) or_return
		case 0x2F:
			parse_cpl(binary, instruction) or_return

		// 0x30 - 0x3F
		case 0x30:
			parse_jr_nc_s8(binary, instruction) or_return
		case 0x31:
			parse_ld_sp_imm16(binary, instruction) or_return
		case 0x32:
			parse_ld_hl_dec_a(binary, instruction) or_return
		case 0x33:
			parse_inc_sp(binary, instruction) or_return
		case 0x34:
			parse_inc_hl_addr(binary, instruction) or_return
		case 0x35:
			parse_dec_hl_addr(binary, instruction) or_return
		case 0x36:
			parse_ld_hl_addr_imm8(binary, instruction) or_return
		case 0x37:
			parse_scf(binary, instruction) or_return
		case 0x38:
			parse_jr_c_s8(binary, instruction) or_return
		case 0x39:
			parse_add_hl_sp(binary, instruction) or_return
		case 0x3A:
			parse_ld_a_hl_dec(binary, instruction) or_return
		case 0x3B:
			parse_dec_sp(binary, instruction) or_return
		case 0x3C:
			parse_inc_a(binary, instruction) or_return
		case 0x3D:
			parse_dec_a(binary, instruction) or_return
		case 0x3E:
			parse_ld_a_imm8(binary, instruction) or_return
		case 0x3F:
			parse_ccf(binary, instruction) or_return
		case 0x76:
			// Handle HALT here because it's the odd instruction in the next range
			parse_halt(binary, instruction) or_return

		// 0x40 - 0x7F
		case 0x40..=0x7F:
			parse_ld(binary, instruction)

		// 0x80 - 0xBF
		case 0x80..=0xBF:
			parse_alu_operation(binary, instruction)

		// 0xC0 - 0xCF
		case 0xC0:
			parse_ret_nz(binary, instruction) or_return
		case 0xC1:
			parse_pop_bc(binary, instruction) or_return
		case 0xC2:
			parse_jp_nz_imm16(binary, instruction) or_return
		case 0xC3:
			parse_jp_imm16(binary, instruction) or_return
		case 0xC4:
			parse_call_nz_imm16(binary, instruction) or_return
		case 0xC5:
			parse_push_bc(binary, instruction) or_return
		case 0xC6:
			parse_add_a_imm8(binary, instruction) or_return
		case 0xC7:
			parse_rst_0(binary, instruction) or_return
		case 0xC8:
			parse_ret_z(binary, instruction) or_return
		case 0xC9:
			parse_ret(binary, instruction) or_return
		case 0xCA:
			parse_jp_z_imm16(binary, instruction) or_return
		case 0xCB:
            // Pop the 0xCB from the binary as we know at this point
            // that we're parsing a 16 bit instruction.
            _ = binary_next(binary) or_return
            parse_bit_manipulation_operation(binary, instruction) or_return
		case 0xCC:
			parse_call_z_imm16(binary, instruction) or_return
		case 0xCD:
			parse_call_imm16(binary, instruction) or_return
		case 0xCE:
			parse_adc_a_imm8(binary, instruction) or_return
		case 0xCF:
			parse_rst_1(binary, instruction) or_return
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

	imm16: u16 = (cast(u16)hi << 8) | (cast(u16)lo)
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .BC }, 
		source = Value { location = imm16 },
	}

	return nil
}

@(test)
test_parse_ld_bc_imm16 :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			source = Value { location = u16(0x01)},
			destination = Value { location = .BC }
		}
	}
	test_instruction_parse(t, []byte{0x01, 0x01, 0x00}, expected)
}

parse_ld_bc_a :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .BC, dereference_in_memory = true },
		source = Value { location = .A }
	}

	return nil
}

@(test)
test_parse_ld_bc_a :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			source = Value { location = .A },
			destination = Value { location = .BC, dereference_in_memory = true }
		}
	}
	test_instruction_parse(t, []byte{0x02}, expected)
}

parse_inc_bc :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.INC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .BC },
	}

	return nil
}

@(test)
test_parse_inc_bc :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.INC,
		type = UnaryArithmetic {
			destination = Value { location = .BC }
		}
	}
	test_instruction_parse(t, []byte{0x03}, expected)
}

parse_inc_b :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.INC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .B }, 
	}

	return nil
}

@(test)
test_parse_inc_b :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.INC,
		type = UnaryArithmetic {
			destination = Value { location = .B }
		}
	}
	test_instruction_parse(t, []byte{0x04}, expected)
}

parse_dec_b :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.DEC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .B }
	}

	return nil
}

@(test)
test_parse_dec_b :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.DEC,
		type = UnaryArithmetic {
			destination = Value { location = .B }
		}
	}
	test_instruction_parse(t, []byte{0x05}, expected)
}

parse_ld_b_imm8 :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	imm8 := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .B },
		source = Value { location = imm8 }
	}

	return nil
}

@(test)
test_parse_ld_b_imm8 :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .B },
			source = Value { location = u8(0x10) }
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
		destination = Value { location = .SP },
		source = Value { location = address, dereference_in_memory = true }
	}
	return nil
}

@(test)
test_parse_ld_addr16_sp :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .SP },
			source = Value { location = u16(0x1234), dereference_in_memory = true }
		}
	}
	test_instruction_parse(t, []byte{0x08, 0x34, 0x12}, expected) // little endian 0x1234
}

parse_add_hl_bc :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.ADD
	instruction.type = BinaryArithmetic {
		destination = Value { location =.HL },
		source = Value { location =.BC }
	}
	return nil
}

@(test)
test_parse_add_hl_bc :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.ADD,
		type = BinaryArithmetic {
			destination = Value { location = .HL },
			source = Value { location = .BC }
		}
	}
	test_instruction_parse(t, []byte{0x09}, expected)
}

parse_ld_a_bc :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .A },
		source = Value { location = .BC, dereference_in_memory = true  }
	}
	return nil
}

@(test)
test_parse_ld_a_bc:: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .A },
			source = Value { location = .BC, dereference_in_memory = true },
		}
	}
	test_instruction_parse(t, []byte{0x0A}, expected)
}

parse_dec_bc :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.DEC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .BC }
	}
	return nil
}

@(test)
test_parse_dec_bc :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.DEC,
		type = UnaryArithmetic {
			destination = Value { location = .BC }
		}
	}
	test_instruction_parse(t, []byte{0x0B}, expected)
}

parse_inc_c :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.INC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .C }
	}
	return nil
}

@(test)
test_parse_inc_c:: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.INC,
		type = UnaryArithmetic {
			destination = Value { location = .C }
		}
	}
	test_instruction_parse(t, []byte{0x0C}, expected)
}

parse_dec_c :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.DEC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .C }
	}
	return nil
}

@(test)
test_parse_dec_c:: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.DEC,
		type = UnaryArithmetic {
			destination = Value { location = .C }
		}
	}
	test_instruction_parse(t, []byte{0x0D}, expected)
}

parse_ld_c_imm8 :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	imm := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .C },
		source = Value { location = imm }
	}
	return nil
}

@(test)
test_parse_ld_c_imm8:: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .C },
			source = Value { location = u8(0xFF) }
 		}
	}
	test_instruction_parse(t, []byte{0x0E, 0xFF}, expected)
}

parse_rrca :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.RRCA
	return nil
}

@(test)
test_parse_rrca :: proc(t: ^testing.T) {
	expected := Instruction{ op = Opcode.RRCA }
	test_instruction_parse(t, []byte{0x0F}, expected)
}

parse_stop:: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	b := binary_next(binary) or_return
	instruction.op = Opcode.STOP
	return nil
}

@(test)
test_parse_stop :: proc(t: ^testing.T) {
	expected := Instruction{op = Opcode.STOP}
	test_instruction_parse(t, []byte{0x10}, expected)
}

parse_ld_de_imm16 :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	lo := binary_next(binary) or_return
	hi := binary_next(binary) or_return

	imm16: u16 = (cast(u16)hi << 8) | (cast(u16)lo)
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .DE, dereference_in_memory = true  },
		source = Value { location = imm16 }
	}

	return nil
}

@(test)
test_parse_ld_de_imm16 :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			source = Value { location = u16(0x0201) },
			destination = Value { location = .DE, dereference_in_memory = true  }
		}
	}
	test_instruction_parse(t, []byte{0x11, 0x01, 0x02}, expected)
}

parse_ld_de_a :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .DE },
		source = Value { location = .A }
	}

	return nil
}

@(test)
test_parse_ld_de_a :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			source = Value { location = .A },
			destination = Value { location = .DE }
		}
	}
	test_instruction_parse(t, []byte{0x12}, expected)
}

parse_inc_de :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.INC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .DE },
	}

	return nil
}

@(test)
test_parse_inc_de :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.INC,
		type = UnaryArithmetic {
			destination = Value { location = .DE }
		}
	}
	test_instruction_parse(t, []byte{0x13}, expected)
}

parse_inc_d :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.INC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .D },
	}

	return nil
}

@(test)
test_parse_inc_d :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.INC,
		type = UnaryArithmetic {
			destination = Value { location = .D }
		}
	}
	test_instruction_parse(t, []byte{0x14}, expected)
}

parse_dec_d :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.DEC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .D },
	}

	return nil
}

@(test)
test_parse_dec_d :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.DEC,
		type = UnaryArithmetic {
			destination = Value { location = .D }
		}
	}
	test_instruction_parse(t, []byte{0x15}, expected)
}

parse_ld_d_imm8 :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	imm8 := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .D },
		source = Value { location = imm8 }
	}

	return nil
}

@(test)
test_parse_ld_d_imm8 :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .D },
			source = Value { location = u8(0x10) }
		}
	}
	test_instruction_parse(t, []byte{0x16, 0x10}, expected)
}

parse_rla :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.RLA
	return nil
}

@(test)
test_parse_rla :: proc(t: ^testing.T) {
	expected := Instruction { op = Opcode.RLA }
	test_instruction_parse(t, []byte{0x17}, expected)
}

parse_jr_s8 :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	steps := binary_next(binary) or_return

	instruction.op = Opcode.JR
	instruction.type = UnconditionalJump{place = Steps(steps)}
	return nil
}

@(test)
test_parse_jr_s8 :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.JR,
		type = UnconditionalJump{place = Steps(0x67)}
	}
	test_instruction_parse(t, []byte{0x18, 0x67}, expected)
}

parse_add_hl_de :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.ADD
	instruction.type = BinaryArithmetic {
		destination = Value { location = .HL },
		source = Value { location = .DE }
	}
	return nil
}

@(test)
test_parse_add_hl_de :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.ADD,
		type = BinaryArithmetic {
			destination = Value { location = .HL },
			source = Value { location = .DE }
		}
	}
	test_instruction_parse(t, []byte{0x19}, expected)
}

parse_ld_a_de :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .A },
		source = Value { location =.DE, dereference_in_memory = true  }
	}
	return nil
}

@(test)
test_parse_ld_a_de:: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .A },
			source = Value { location = .DE, dereference_in_memory = true }
		}
	}
	test_instruction_parse(t, []byte{0x1A}, expected)
}

parse_dec_de :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.DEC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .DE }
	}
	return nil
}

@(test)
test_parse_dec_de:: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.DEC,
		type = UnaryArithmetic {
			destination = Value { location = .DE }
		}
	}
	test_instruction_parse(t, []byte{0x1B}, expected)
}

parse_inc_e :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.INC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .E }
	}
	return nil
}

@(test)
test_parse_inc_e :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.INC,
		type = UnaryArithmetic {
			destination = Value { location = .E }
		}
	}
	test_instruction_parse(t, []byte{0x1C}, expected)
}

parse_dec_e :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.DEC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .E }
	}
	return nil
}

@(test)
test_parse_dec_e :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.DEC,
		type = UnaryArithmetic {
			destination = Value { location = .E }
		}
	}
	test_instruction_parse(t, []byte{0x1D}, expected)
}

parse_ld_e_imm8 :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	imm := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .E },
		source = Value { location = imm }
	}
	return nil
}

@(test)
test_parse_ld_e_imm8:: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .E },
			source = Value { location = u8(0xEE) }
		}
	}
	test_instruction_parse(t, []byte{0x1E, 0xEE}, expected)
}

parse_rra :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.RRA
	return nil
}

@(test)
test_parse_rra :: proc(t: ^testing.T) {
	expected := Instruction{ op = Opcode.RRA }
	test_instruction_parse(t, []byte{0x1F}, expected)
}

parse_jr_nz_s8:: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte:= binary_next(binary) or_return
	steps := binary_next(binary) or_return

	instruction.op = Opcode.JR
	instruction.type =  ConditionalJump {
		place = Steps(steps),
		flag = Flag.Z,
		set = false
	}
	return nil
}

@(test)
test_parse_jr_nz_s8 :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.JR,
		type = ConditionalJump {
			place = Steps(0x10),
			flag = Flag.Z,
			set = false
		}
	}
	test_instruction_parse(t, []byte{0x20, 0x10}, expected)
}

parse_ld_hl_inc_imm16 :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	lo := binary_next(binary) or_return
	hi := binary_next(binary) or_return

	imm16: u16 = (cast(u16)hi << 8) | (cast(u16)lo)
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value {
			location = .HL,
			dereference_in_memory = true,
			postfix_operator = .Increment
		},
		source = Value { location = imm16 }
	}

	return nil
}

@(test)
test_parse_ld_hl_inc_imm16 :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			source = Value { location = u16(0x0201) },
			destination = Value {
				location = . HL,
				dereference_in_memory = true,
				postfix_operator = .Increment
			}
		}
	}
	test_instruction_parse(t, []byte{0x21, 0x01, 0x02}, expected)
}

parse_ld_hl_a :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = . HL },
		source = Value { location = .A }
	}

	return nil
}

@(test)
test_parse_ld_hl_a :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			source = Value { location = .A },
			destination = Value { location = . HL }
		}
	}
	test_instruction_parse(t, []byte{0x22}, expected)
}

parse_inc_hl :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.INC
	instruction.type = UnaryArithmetic {
		destination = Value { location = . HL },
	}

	return nil
}

@(test)
test_parse_inc_hl :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.INC,
		type = UnaryArithmetic {
			destination = Value { location = .HL }
		}
	}
	test_instruction_parse(t, []byte{0x23}, expected)
}

parse_inc_h :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.INC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .H },
	}

	return nil
}

@(test)
test_parse_inc_H :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.INC,
		type = UnaryArithmetic {
			destination = Value { location = .H }
		}
	}
	test_instruction_parse(t, []byte{0x24}, expected)
}

parse_dec_h :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.DEC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .H },
	}

	return nil
}

@(test)
test_parse_dec_h :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.DEC,
		type = UnaryArithmetic {
			destination = Value { location = .H }
		}
	}
	test_instruction_parse(t, []byte{0x25}, expected)
}

parse_ld_h_imm8 :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	imm8 := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .H },
		source = Value { location = u8(imm8) }
	}

	return nil
}

@(test)
test_parse_ld_h_imm8 :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .H },
			source = Value { location = u8(0x10) }
		}
	}
	test_instruction_parse(t, []byte{0x26, 0x10}, expected)
}

parse_daa :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.DAA
	return nil
}

@(test)
test_parse_daa :: proc(t: ^testing.T) {
	expected := Instruction { op = Opcode.DAA }
	test_instruction_parse(t, []byte{0x27}, expected)
}

parse_jr_z_s8 :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	steps := binary_next(binary) or_return

	instruction.op = Opcode.JR
	instruction.type = ConditionalJump {
		place = Steps(steps),
		flag = Flag.Z,
		set = true
	}
	return nil
}

@(test)
test_parse_jr_z_s8 :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.JR,
		type = ConditionalJump {
			place = Steps(0x67),
			flag = Flag.Z,
			set = true
		}
	}
	test_instruction_parse(t, []byte{0x28, 0x67}, expected)
}

parse_add_hl_hl :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.ADD
	instruction.type = BinaryArithmetic {
		destination = Value { location = .HL },
		source = Value { location = .HL }
	}
	return nil
}

@(test)
test_parse_add_hl_hl :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.ADD,
		type = BinaryArithmetic {
			destination = Value { location = .HL },
			source = Value { location = .HL }
		}
	}
	test_instruction_parse(t, []byte{0x29}, expected)
}

parse_ld_a_hl_inc :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .A },
		source = Value {
			location = .HL,
			dereference_in_memory = true,
			postfix_operator = .Increment
		}
	}
	return nil
}

@(test)
test_parse_ld_a_hl_inc :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .A },
			source = Value {
				location = .HL,
				dereference_in_memory = true,
				postfix_operator = .Increment
			}
		}
	}
	test_instruction_parse(t, []byte{0x2A}, expected)
}

parse_dec_hl :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.DEC
	instruction.type = UnaryArithmetic {
		destination = Value {location = .HL }
	}
	return nil
}

@(test)
test_parse_dec_hl :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.DEC,
		type = UnaryArithmetic {
			destination = Value { location = .HL }
		}
	}
	test_instruction_parse(t, []byte{0x2B}, expected)
}

parse_inc_l :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.INC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .L }
	}
	return nil
}

@(test)
test_parse_inc_l :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.INC,
		type = UnaryArithmetic {
			destination = Value { location = .L }
		}
	}
	test_instruction_parse(t, []byte{0x2C}, expected)
}

parse_dec_l :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.DEC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .L }
	}
	return nil
}

@(test)
test_parse_dec_l :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.DEC,
		type = UnaryArithmetic {
			destination = Value { location = .L }
		}
	}
	test_instruction_parse(t, []byte{0x2D}, expected)
}

parse_ld_l_imm8 :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	imm := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .L },
		source = Value { location = imm }
	}
	return nil
}

@(test)
test_parse_ld_l_imm8:: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .L },
			source = Value { location = u8(0xEE) }
		}
	}
	test_instruction_parse(t, []byte{0x2E, 0xEE}, expected)
}

parse_cpl :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.CPL
	return nil
}

@(test)
test_parse_cpl :: proc(t: ^testing.T) {
	expected := Instruction{ op = Opcode.CPL }
	test_instruction_parse(t, []byte{0x2F}, expected)
}

parse_jr_nc_s8:: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	steps := binary_next(binary) or_return

	instruction.op = Opcode.JR
	instruction.type =  ConditionalJump {
		place = Steps(steps),
		flag = Flag.C,
		set = false
	}
	return nil
}

@(test)
test_parse_jr_nc_s8 :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.JR,
		type = ConditionalJump {
			place = Steps(0x20),
			flag = Flag.C,
			set = false
		}
	}
	test_instruction_parse(t, []byte{0x30, 0x20}, expected)
}

parse_ld_sp_imm16 :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	lo := binary_next(binary) or_return
	hi := binary_next(binary) or_return

	imm16: u16 = (cast(u16)hi << 8) | (cast(u16)lo)
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .SP },
		source = Value { location = imm16 }
	}

	return nil
}

@(test)
test_parse_ld_sp_imm16 :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			source = Value { location = u16(0x0201) },
			destination = Value { location = .SP }
		}
	}
	test_instruction_parse(t, []byte{0x31, 0x01, 0x02}, expected)
}

parse_ld_hl_dec_a :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value {
			location = .HL,
			dereference_in_memory = true,
			postfix_operator = .Increment
		},
		source = Value { location = .A }
	}

	return nil
}

@(test)
test_parse_ld_hl_dec_a :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			source = Value { location = .A },
			destination = Value {
				location = .HL,
				dereference_in_memory = true,
				postfix_operator = .Increment
			}
		}
	}
	test_instruction_parse(t, []byte{0x32}, expected)
}

parse_inc_sp :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.INC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .SP },
	}

	return nil
}

@(test)
test_parse_inc_sp :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.INC,
		type = UnaryArithmetic {
			destination = Value { location = .SP }
		}
	}
	test_instruction_parse(t, []byte{0x33}, expected)
}

parse_inc_hl_addr :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.INC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .HL, dereference_in_memory = true },
	}

	return nil
}

@(test)
test_parse_inc_h_addr :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.INC,
		type = UnaryArithmetic {
			destination = Value { location = .HL, dereference_in_memory = true }
		}
	}
	test_instruction_parse(t, []byte{0x34}, expected)
}

parse_dec_hl_addr :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.DEC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .HL, dereference_in_memory = true },
	}

	return nil
}

@(test)
test_parse_dec_hl_addr :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.DEC,
		type = UnaryArithmetic {
			destination = Value { location = .HL, dereference_in_memory = true }
		}
	}
	test_instruction_parse(t, []byte{0x35}, expected)
}

parse_ld_hl_addr_imm8 :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	imm8 := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .HL, dereference_in_memory = true },
		source = Value { location = u8(imm8) }
	}

	return nil
}

@(test)
test_parse_ld_hl_addr_imm8 :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .HL, dereference_in_memory = true },
			source = Value { location = u8(0x10) }
		}
	}
	test_instruction_parse(t, []byte{0x36, 0x10}, expected)
}

parse_scf :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.SCF
	return nil
}

@(test)
test_parse_scf :: proc(t: ^testing.T) {
	expected := Instruction { op = Opcode.SCF }
	test_instruction_parse(t, []byte{0x37}, expected)
}

parse_jr_c_s8 :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	steps := binary_next(binary) or_return

	instruction.op = Opcode.JR
	instruction.type = ConditionalJump {
		place = Steps(steps),
		flag = Flag.C,
		set = true
	}
	return nil
}

@(test)
test_parse_jr_c_s8 :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.JR,
		type = ConditionalJump {
			place = Steps(0x67),
			flag = Flag.C,
			set = true
		}
	}
	test_instruction_parse(t, []byte{0x38, 0x67}, expected)
}

parse_add_hl_sp :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.ADD
	instruction.type = BinaryArithmetic {
		destination = Value { location = .HL },
		source = Value { location = .SP }
	}
	return nil
}

@(test)
test_parse_add_hl_sp :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.ADD,
		type = BinaryArithmetic {
			destination = Value { location = .HL },
			source = Value { location = .SP }
		}
	}
	test_instruction_parse(t, []byte{0x39}, expected)
}

parse_ld_a_hl_dec :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .A },
		source = Value {
			location = .HL,
			dereference_in_memory = true,
			postfix_operator = .Decrement
		}
	}
	return nil
}

@(test)
test_parse_ld_a_hl_dec :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .A },
			source = Value {
				location = .HL,
				dereference_in_memory = true,
				postfix_operator = .Decrement
			}
		}
	}
	test_instruction_parse(t, []byte{0x3A}, expected)
}

parse_dec_sp :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.DEC
	instruction.type = UnaryArithmetic {
		destination = Value {location = .SP }
	}
	return nil
}

@(test)
test_parse_dec_sp :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.DEC,
		type = UnaryArithmetic {
			destination = Value { location = .SP }
		}
	}
	test_instruction_parse(t, []byte{0x3B}, expected)
}

parse_inc_a :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.INC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .A }
	}
	return nil
}

@(test)
test_parse_inc_a :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.INC,
		type = UnaryArithmetic {
			destination = Value { location = .A }
		}
	}
	test_instruction_parse(t, []byte{0x3C}, expected)
}

parse_dec_a :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.DEC
	instruction.type = UnaryArithmetic {
		destination = Value { location = .A }
	}
	return nil
}

@(test)
test_parse_dec_a :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.DEC,
		type = UnaryArithmetic {
			destination = Value { location = .A }
		}
	}
	test_instruction_parse(t, []byte{0x3D}, expected)
}

parse_ld_a_imm8 :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	imm := binary_next(binary) or_return
	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = Value { location = .A },
		source = Value { location = imm }
	}
	return nil
}

@(test)
test_parse_ld_a_imm8:: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .A },
			source = Value { location = u8(0xEE) }
		}
	}
	test_instruction_parse(t, []byte{0x3E, 0xEE}, expected)
}

parse_ccf :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.CCF
	return nil
}

@(test)
test_parse_ccf :: proc(t: ^testing.T) {
	expected := Instruction{ op = Opcode.CCF }
	test_instruction_parse(t, []byte{0x3F}, expected)
}

parse_halt :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.HALT
	return nil
}

@(test)
test_parse_halt :: proc(t: ^testing.T) {
	expected := Instruction{ op = Opcode.HALT }
	test_instruction_parse(t, []byte{0x76}, expected)
}

map_bits_to_register :: proc (bits: u8) -> Value {
	out := Value { location = .B }
	switch bits {
		case 0b000: out = Value { location = .B }
		case 0b001: out = Value { location = .C }
		case 0b010: out = Value { location = .D }
		case 0b011: out = Value { location = .E }
		case 0b100: out = Value { location = .H }
		case 0b101: out = Value { location = .L }
		case 0b110:
			// The HL is the odd one in this mapping that dereferences memory every time.
			out = Value { location = .HL, dereference_in_memory = true }
		case 0b111: out = Value { location = .A }
	}

	return out
}

parse_ld :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	load_op_byte := binary_next(binary) or_return
	destination_bits := (load_op_byte >> 3) & 0x07 // 00xxx000
	source_bits := load_op_byte & 0x07             // 00000xxx

	// Map bits to their register values.
	destination := map_bits_to_register(destination_bits)
	source := map_bits_to_register(source_bits)

	instruction.op = Opcode.LD
	instruction.type = Load {
		destination = destination,
		source = source
	}

	return nil
}

@(test)
test_parse_ld_b_b :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .B },
			source = Value { location = .B }
		}
	}
	test_instruction_parse(t, []byte{0x40}, expected)
}

@(test)
test_parse_ld_d_b :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .D },
			source = Value { location = .B }
		}
	}
	test_instruction_parse(t, []byte{0x50}, expected)
}

@(test)
test_parse_ld_h_b :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .H },
			source = Value { location = .B }
		}
	}
	test_instruction_parse(t, []byte{0x60}, expected)
}

@(test)
test_parse_ld_hl_b :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .HL, dereference_in_memory = true },
			source = Value { location = .B }
		}
	}
	test_instruction_parse(t, []byte{0x70}, expected)
}

@(test)
test_parse_ld_e_a :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .E },
			source = Value { location = .A }
		}
	}
	test_instruction_parse(t, []byte{0x5F}, expected)
}

@(test)
test_parse_ld_ld_c_l :: proc(t: ^testing.T) {
	expected := Instruction{
		op = Opcode.LD,
		type = Load {
			destination = Value { location = .C },
			source = Value { location = .L }
		}
	}
	test_instruction_parse(t, []byte{0x4D}, expected)
}

map_bits_to_opcode :: proc (bits: u8) -> Opcode {
	switch(bits) {
	case 0b000:
		return Opcode.ADD
	case 0b001:
		return Opcode.ADC
	case 0b010:
		return Opcode.SUB
	case 0b011:
		return Opcode.SBC
	case 0b100:
		return Opcode.AND
	case 0b101:
		return Opcode.XOR
	case 0b110:
		return Opcode.OR
	case:
		return Opcode.CP
	}
}

parse_alu_operation :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	operation_bits := (op_byte >> 3) & 0x07  // 00xxx000
	source_register := op_byte & 0x07        // 00000xxx

	opcode := map_bits_to_opcode(operation_bits)
	source := map_bits_to_register(source_register)

	instruction.op = opcode
	instruction.type = BinaryArithmetic {
		destination = Value { location = .A },
		source = source
	}

	return nil
}

@(test)
test_parse_add_a_b :: proc(t: ^testing.T) {
	expected := Instruction {
		op = Opcode.ADD,
		type = BinaryArithmetic {
			destination = Value { location = .A },
			source = Value { location = .B }
		}
	}
	test_instruction_parse(t, []byte{0x80}, expected)
}

@(test)
test_parse_add_a_hl :: proc(t: ^testing.T) {
	expected := Instruction {
		op = Opcode.ADD,
		type = BinaryArithmetic {
			destination = Value { location = .A },
			source = Value { location = .HL, dereference_in_memory = true }
		}
	}
	test_instruction_parse(t, []byte{0x86}, expected)
}

@(test)
test_parse_adc_a_d :: proc(t: ^testing.T) {
	expected := Instruction {
		op = Opcode.ADC,
		type = BinaryArithmetic {
			destination = Value { location = .A },
			source = Value { location = .D }
		}
	}
	test_instruction_parse(t, []byte{0x8A}, expected)
}

@(test)
test_parse_adc_a_h :: proc(t: ^testing.T) {
	expected := Instruction {
		op = Opcode.ADC,
		type = BinaryArithmetic {
			destination = Value { location = .A },
			source = Value { location = .H }
		}
	}
	test_instruction_parse(t, []byte{0x8C}, expected)
}

@(test)
test_parse_sub_c :: proc (t: ^testing.T) {
	expected := Instruction {
		op = Opcode.SUB,
		type = BinaryArithmetic {
			destination = Value { location = .A },
			source = Value { location = .C }
		}
	}
	test_instruction_parse(t, []byte{0x91}, expected)
}

@(test)
test_parse_sub_e :: proc (t: ^testing.T) {
	expected := Instruction {
		op = Opcode.SUB,
		type = BinaryArithmetic {
			destination = Value { location = .A },
			source = Value { location = .E }
		}
	}
	test_instruction_parse(t, []byte{0x93}, expected)
}

@(test)
test_parse_sbc_a_h :: proc(t: ^testing.T) {
	expected := Instruction {
		op = Opcode.SBC,
		type = BinaryArithmetic {
			destination = Value { location = .A },
			source = Value { location = .H }
		}
	}
	test_instruction_parse(t, []byte{0x9C}, expected)
}

@(test)
test_parse_and_l :: proc(t: ^testing.T) {
	expected := Instruction {
		op = Opcode.AND,
		type = BinaryArithmetic {
			destination = Value { location = .A },
			source = Value { location = .L }
		}
	}
	test_instruction_parse(t, []byte{0xA5}, expected)
}

@(test)
test_parse_xor_a :: proc(t: ^testing.T) {
	expected := Instruction {
		op = Opcode.XOR,
		type = BinaryArithmetic {
			destination = Value { location = .A },
			source = Value { location = .A }
		}
	}
	test_instruction_parse(t, []byte{0xAF}, expected)
}

@(test)
test_parse_or_d :: proc(t: ^testing.T) {
	expected := Instruction {
		op = Opcode.OR,
		type = BinaryArithmetic {
			destination = Value { location = .A },
			source = Value { location = .D }
		}
	}
	test_instruction_parse(t, []byte{0xB2}, expected)
}

@(test)
test_parse_or_h :: proc(t: ^testing.T) {
	expected := Instruction {
		op = Opcode.OR,
		type = BinaryArithmetic {
			destination = Value { location = .A },
			source = Value { location = .H }
		}
	}
	test_instruction_parse(t, []byte{0xB4}, expected)
}

@(test)
test_parse_cp_b :: proc(t: ^testing.T) {
	expected := Instruction {
		op = Opcode.CP,
		type = BinaryArithmetic {
			destination = Value { location = .A },
			source = Value { location = .B }
		}
	}
	test_instruction_parse(t, []byte{0xB8}, expected)
}

parse_ret_nz :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return

	instruction.op = Opcode.RET
	instruction.type = ConditionalReturn {
		flag = .Z,
		set = false
	}
	return nil
}

@(test)
test_parse_ret_nz :: proc (t: ^testing.T) {
	expected := Instruction {
		op = Opcode.RET,
		type = ConditionalReturn {
			flag = .Z,
			set = false
		}
	}
	test_instruction_parse(t, []byte{0xC0}, expected)
}

parse_pop_bc :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = Opcode.POP
	instruction.type = StackControl {
		destination = Value { location = .BC }
	}
	return nil
}

@(test)
test_parse_pop_bc :: proc (t: ^testing.T) {
	expected := Instruction {
		op = Opcode.POP,
		type = StackControl {
			destination = Value { location = .BC }
		}
	}
	test_instruction_parse(t, []byte{0xC1}, expected)
}

parse_jp_nz_imm16 :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return

	lo := binary_next(binary) or_return
	hi := binary_next(binary) or_return

	imm16: u16 = (cast(u16)hi << 8) | (cast(u16)lo)

	instruction.op = Opcode.JP
	instruction.type = ConditionalJump {
		place = Location(imm16),
		flag = .Z,
		set = false
	}
	
	return nil
}

@(test)
test_parse_jp_nz_imm16 :: proc (t: ^testing.T) {
	expected := Instruction {
		op = .JP,
		type = ConditionalJump {
			place = Location(0x1234),
			flag = .Z,
			set = false
		}
	}
	test_instruction_parse(t, []byte{0xC2, 0x34, 0x12}, expected)
}

parse_jp_imm16 :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return

	lo := binary_next(binary) or_return
	hi := binary_next(binary) or_return
	imm16: u16 = (cast(u16)hi << 8) | (cast(u16)lo)

	instruction.op = .JP
	instruction.type = UnconditionalJump {
		place = Location(imm16)
	}
	return nil
}

@(test)
test_parse_jp_imm16 :: proc (t: ^testing.T) {
	expected := Instruction {
		op = .JP,
		type = UnconditionalJump {
			place = Location(0x1234),
		}
	}
	test_instruction_parse(t, []byte{0xC3, 0x34, 0x12}, expected)
}

parse_call_nz_imm16 :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return

	lo := binary_next(binary) or_return
	hi := binary_next(binary) or_return
	imm16: u16 = (cast(u16)hi << 8) | (cast(u16)lo)

	instruction.op = .CALL
	instruction.type = ConditionalJump {
		flag = .Z,
		set = false,
		place = Location(imm16)
	}

	return nil
}

@(test)
test_parse_call_nz_imm16 :: proc (t: ^testing.T) {
	expected := Instruction {
		op = .CALL,
		type = ConditionalJump {
			flag = .Z,
			set = false,
			place = Location(0x3412),
		}
	}
	test_instruction_parse(t, []byte{0xC4, 0x12, 0x34}, expected)
}

parse_push_bc :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return

	instruction.op = .PUSH
	instruction.type = StackControl {
		destination = Value { location = .BC }
	}

	return nil
}

@(test)
test_parse_push_bc :: proc (t: ^testing.T) {
	expected := Instruction {
		op = .PUSH,
		type = StackControl {
			destination = Value { location = .BC }
		}
	}
	test_instruction_parse(t, []byte{0xC5}, expected)
}

parse_add_a_imm8 :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	imm8 := binary_next(binary) or_return

	instruction.op = .ADD
	instruction.type = BinaryArithmetic {
		destination = Value { location = .A },
		source = Value { location = u8(imm8) }
	}

	return nil
}

@(test)
test_parse_add_a_imm8 :: proc (t: ^testing.T) {
	expected := Instruction {
		op = .ADD,
		type = BinaryArithmetic {
			destination = Value { location = .A },
			source = Value { location = u8(0x67) }
		}
	}
	test_instruction_parse(t, []byte{0xC6, 0x67}, expected)
}

parse_rst_0 :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return

	instruction.op = .RST
	instruction.type = UnconditionalJump {
		place = Location(0x0000)
	}

	return nil
}

@(test)
test_parse_rst_0 :: proc (t: ^testing.T) {
	expected := Instruction {
		op = .RST,
		type = UnconditionalJump {
			place = Location(0x0000)
		}
	}
	test_instruction_parse(t, []byte{0xC7}, expected)
}

parse_ret_z :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return

	instruction.op = .RET
	instruction.type = ConditionalJump {
		flag = .Z,
		set = true
	}

	return nil
}

@(test)
test_parse_ret_z :: proc (t: ^testing.T) {
	expected := Instruction {
		op = .RET,
		type = ConditionalJump {
			flag = .Z,
			set = true
		}
	}
	test_instruction_parse(t, []byte{0xC8}, expected)
}

parse_ret :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	instruction.op = .RET
	return nil
}

@(test)
test_parse_ret :: proc (t: ^testing.T) {
	expected := Instruction { op = .RET }
	test_instruction_parse(t, []byte{0xC9}, expected)
}

parse_jp_z_imm16 :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return

	lo := binary_next(binary) or_return
	hi := binary_next(binary) or_return

	imm16: u16 = (cast(u16)hi << 8) | (cast(u16)lo)

	instruction.op = Opcode.JP
	instruction.type = ConditionalJump {
		place = Location(imm16),
		flag = .Z,
		set = true
	}
	
	return nil
}

@(test)
test_parse_jp_z_imm16 :: proc (t: ^testing.T) {
	expected := Instruction {
		op = .JP,
		type = ConditionalJump {
			place = Location(0x1234),
			flag = .Z,
			set = true
		}
	}
	test_instruction_parse(t, []byte{0xCA, 0x34, 0x12}, expected)
}

parse_call_z_imm16 :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return

	lo := binary_next(binary) or_return
	hi := binary_next(binary) or_return
	imm16: u16 = (cast(u16)hi << 8) | (cast(u16)lo)

	instruction.op = .CALL
	instruction.type = ConditionalJump {
		flag = .Z,
		set = true,
		place = Location(imm16)
	}

	return nil
}

@(test)
test_parse_call_z_imm16 :: proc (t: ^testing.T) {
	expected := Instruction {
		op = .CALL,
		type = ConditionalJump {
			flag = .Z,
			set = true,
			place = Location(0x3412),
		}
	}
	test_instruction_parse(t, []byte{0xCC, 0x12, 0x34}, expected)
}

parse_call_imm16 :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return

	lo := binary_next(binary) or_return
	hi := binary_next(binary) or_return
	imm16: u16 = (cast(u16)hi << 8) | (cast(u16)lo)

	instruction.op = .CALL
	instruction.type = UnconditionalJump{
		place = Location(imm16)
	}

	return nil
}

@(test)
test_parse_call_imm16 :: proc (t: ^testing.T) {
	expected := Instruction {
		op = .CALL,
		type = UnconditionalJump {
			place = Location(0x6769),
		}
	}
	test_instruction_parse(t, []byte{0xCD, 0x69, 0x67}, expected)
}

parse_adc_a_imm8 :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return
	imm8 := binary_next(binary) or_return

	instruction.op = .ADC
	instruction.type = BinaryArithmetic {
		destination = Value { location = .A },
		source = Value { location = u8(imm8)}
	}

	return nil
}

@(test)
test_parse_adc_a_imm8 :: proc (t: ^testing.T) {
	expected := Instruction {
		op = .ADC,
		type = BinaryArithmetic {
			destination = Value { location = .A },
			source = Value { location = u8(0x67) }
		}
	}
	test_instruction_parse(t, []byte{0xCE, 0x67}, expected)
}

parse_rst_1 :: proc(binary: ^Binary, instruction: ^Instruction) -> Error {
	op_byte := binary_next(binary) or_return

	instruction.op = .RST
	instruction.type = UnconditionalJump {
		place = Location(0x0008)
	}

	return nil
}

@(test)
test_parse_rst_1 :: proc (t: ^testing.T) {
	expected := Instruction {
		op = .RST,
		type = UnconditionalJump {
			place = Location(0x0008)
		}
	}
	test_instruction_parse(t, []byte{0xCF}, expected)
}

parse_bit_manipulation_operation :: proc (binary: ^Binary, instruction: ^Instruction) -> Error {
	// The 0xCB instructions follow a bit pattern of GGOOOTTT where:
	//  - GG  makes up the instruction group
	//  - OOO makes up the operation in that instruction group
	//  - TTT makes up the target of the operation

	op_byte        := binary_next(binary) or_return
	group_bits     := (op_byte >> 6) & 0b00000011 // 000000GG
	operation_bits := (op_byte >> 3) & 0b00000111 // 00000OOO
	target_bits    := op_byte        & 0b00000111 // 00000TTT

	register := map_bits_to_register(target_bits)

    if group_bits == 0b00 {
        // For the bit shifting and rotating group,
        // the operation_bits tell us which Opcode
        // is being used.
        switch(operation_bits) {
        case 0b000:
            instruction.op = .RLC
        case 0b001:
            instruction.op = .RRC
        case 0b010:
            instruction.op = .RL
        case 0b011:
            instruction.op = .RR
        case 0b100:
            instruction.op = .SLA
        case 0b101:
            instruction.op = .SRA
        case 0b110:
            instruction.op = .SWAP
        case:
            instruction.op = .SRL
        }
        instruction.type = BitShift {
            destination = register
        }
        return nil
    }

    switch(group_bits) {
    case 0b00:
    case 0b01:
        instruction.op = .BIT
    case 0b10:
        instruction.op = .RES
    case 0b11:
        instruction.op = .SET
    }
    instruction.type = RegisterBit {
        bit = operation_bits,
        register = register,
    }

	return nil
}

@(test)
test_parse_rlc_b :: proc (t: ^testing.T) {
	expected := Instruction {
		op = .RLC,
		type = BitShift {
			destination = Value { location = .B }
		}
	}
	test_instruction_parse(t, []byte{0xCB, 0x00}, expected)
}

@(test)
test_parse_bit_3_d :: proc (t: ^testing.T) {
    expected := Instruction {
        op = .BIT,
        type = RegisterBit {
            bit = 0x03,
            register = Value { location = .D }
        }
    }
    test_instruction_parse(t, []byte{0xCB, 0x5A}, expected)
}

@(test)
test_parse_res_4_e :: proc (t: ^testing.T) {
	expected := Instruction {
		op = .RES,
		type = RegisterBit {
            bit = 0x04,
			register = Value { location = .E }
		}
	}
	test_instruction_parse(t, []byte{0xCB, 0xA3}, expected)
}

@(test)
test_parse_set_6_hl :: proc (t: ^testing.T) {
    expected := Instruction {
        op = .SET,
        type = RegisterBit {
            bit = 0x06,
            register = Value { location = .HL, dereference_in_memory = true }
        }
    }
    test_instruction_parse(t, []byte{0xCB, 0xF6}, expected)
}
