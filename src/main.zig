const std = @import("std");
const decoder = @import("decoder.zig");
const cpu = @import("cpu.zig");

pub fn main() void {
    var mem = [_]u8{0} ** cpu.MEM_SIZE;
    var state = cpu.CPU{
        .pc = 0,
        .ac = 0,
        .x = 0,
        .y = 0,
        .sr = 0,
        .neg = 0,
        .overflow = 0,
        .brk = 0,
        .dec = 0,
        .int = 0,
        .zero = 0,
        .carry = 0,
    };
    while (true) {
        const insn = mem[state.pc];
        const am = decoder.addressing_mode[insn];
        const opc = decoder.opcode[(insn & 0b11100000) >> 3 | (insn & 0b11)];
        const op8 = am.getOp8(&mem, &state);
        const op16 = am.getOp16(&mem, &state);
        state.pc = opc.getExecutor()(&mem, &state, am, op8, op16);
    }
}
