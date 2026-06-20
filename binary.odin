package main

import "core:os"
import "core:mem"

BinaryError :: enum {
	None,
	EOF
}

Binary :: struct {
	buf: []byte,
	allocator: mem.Allocator,
	pos: int
}

binary_read_rom :: proc(path: string, allocator: mem.Allocator) -> (^Binary, os.Error) {
	buf, err := os.read_entire_file(path, allocator)
	switch err {
	case nil:
	case:
		return nil, err
	}

	binary := new(Binary)
	binary.buf = buf
	binary.allocator = allocator
	binary.pos = 0

	return binary, err
}

binary_peek :: proc(binary: ^Binary) -> (byte, BinaryError) {
	if binary.pos < len(binary.buf) {
		return binary.buf[binary.pos], .None
	}

	return 0, .EOF
}

binary_next :: proc(binary: ^Binary) -> (byte, BinaryError) {
	b, err := binary_peek(binary)
	if err != nil {
		return 0, err
	}

	binary.pos += 1
	return b, .None
}
