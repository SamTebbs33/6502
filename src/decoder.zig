const cpu = @import("cpu.zig");
const CPU = cpu.CPU;
const MEM_SIZE = cpu.MEM_SIZE;

const Executor = fn (mem: *[MEM_SIZE]u8, state: *CPU, am: AM, op8: u8, op16: u16) u16;

pub fn execADC(mem: *[MEM_SIZE]u8, state: *CPU, am: AM, op8: u8, op16: u16) u16 {
    _ = mem;
    _ = state;
    _ = op8;
    _ = op16;
    return state.pc + 1 + am.getSize();
}

const Opcode = enum {
    ADC,
    pub fn getExecutor(self: Opcode) Executor {
        return switch (self) {
            .ADC => execADC,
        };
    }
};

const AM = enum {
    Accumulator,
    Absolute,
    AbsoluteX,
    AbsoluteY,
    Immediate,
    Implied,
    Indirect,
    IndirectX,
    IndirectY,
    Relative,
    Zeropage,
    ZeropageX,
    ZeropageY,

    pub fn getSize(self: AM) u16 {
        return switch (self) {
            .Accumulator, .Implied => 0,
            .Immediate, .Relative, .Zeropage, .ZeropageX, .ZeropageY, .IndirectX, .IndirectY => 1,
            .Absolute, .AbsoluteX, .AbsoluteY, .Indirect => 2,
        };
    }

    pub fn getOp8(self: AM, mem: *[65535]u8, state: *CPU) u8 {
        const low = mem[state.pc + 2];
        const high = mem[state.pc + 1];
        const high_low: u16 = @as(u16, high) << 8 | low;
        return switch (self) {
            .Accumulator => state.ac,
            .Immediate => mem[state.pc + 1],
            .Indirect => mem[high_low],
            .IndirectX => mem[low + state.x],
            .IndirectY => mem[low + state.y],
            .Zeropage, .ZeropageX, .ZeropageY, .Relative, .Absolute, .AbsoluteX, .AbsoluteY, .Implied => 0,
        };
    }

    pub fn getOp16(self: AM, mem: *[65535]u8, state: *CPU) u8 {
        const low = mem[state.pc + 2];
        const high = mem[state.pc + 1];
        const high_low = @as(u16, high) << 8 | low;
        return switch (self) {
            .Zeropage => high,
            .ZeropageX => high + state.x,
            .ZeropageY => high + state.y,
            .Relative => @intCast(u16, @as(i32, state.pc) + @bitCast(i8, high)),
            .Absolute => high_low,
            .AbsoluteX => high_low + state.x,
            .AbsoluteY => high_low + state.y,
            .Accumulator, .Implied, .Immediate, .Indirect, .IndirectX, .IndirectY => 0,
        };
    }
};

pub const addressing_mode = init: {
    var arr = [_]AM{.Implied} ** 255;

    var high: u8 = 0;
    var low: u8 = 0;

    // Implied and relative
    while (high < 0x8) : (high += 1) {
        if (high % 2 == 0) {
            arr[high << 4 | low] = .Implied;
        } else {
            arr[high << 4 | low] = .Relative;
        }
    }

    // Relative and immediate
    high = 0x9;
    while (high <= 0xF) : (high += 1) {
        if (high % 2 == 0) {
            arr[high << 4 | low] = .Relative;
        } else {
            arr[high << 4 | low] = .Immediate;
        }
    }

    high = 0;
    low = 1;
    // X indirect and Y indirect
    while (high <= 0xF) : (high += 1) {
        if (high % 2 == 0) {
            arr[high << 4 | low] = .IndirectX;
        } else {
            arr[high << 4 | low] = .IndirectY;
        }
    }

    // Immediate
    arr[0xA << 4 | 2] = .Immediate;

    // Zeropage
    arr[0x2 << 4 | 4] = .Zeropage;
    arr[0xE << 4 | 4] = .Zeropage;

    // Zeropage, Y zeropage and X zeropage
    low = 4;
    high = 8;
    while (high <= 0xC) : (high += 1) {
        if (high % 2 == 0) {
            arr[high << 4 | low] = .Zeropage;
        } else {
            arr[high << 4 | low] = .ZeropageX;
        }
    }
    low = 5;
    high = 0;
    while (high <= 0xF) : (high += 1) {
        if (high % 2 == 0) {
            arr[high << 4 | low] = .Zeropage;
        } else {
            arr[high << 4 | low] = .ZeropageX;
        }
    }
    low = 6;
    high = 0;
    while (high <= 0x7) : (high += 1) {
        if (high % 2 == 0) {
            arr[high << 4 | low] = .Zeropage;
        } else {
            arr[high << 4 | low] = .ZeropageX;
        }
    }
    low = 6;
    high = 8;
    while (high <= 0xB) : (high += 1) {
        if (high % 2 == 0) {
            arr[high << 4 | low] = .Zeropage;
        } else {
            arr[high << 4 | low] = .ZeropageY;
        }
    }
    low = 6;
    high = 0xC;
    while (high <= 0xF) : (high += 1) {
        if (high % 2 == 0) {
            arr[high << 4 | low] = .Zeropage;
        } else {
            arr[high << 4 | low] = .ZeropageX;
        }
    }

    // Immediate and Y absolute
    low = 9;
    high = 0;
    while (high <= 0xF) : (high += 1) {
        if (high % 2 == 0) {
            arr[high << 4 | low] = .Immediate;
        } else {
            arr[high << 4 | low] = .AbsoluteY;
        }
    }

    // Accumulator
    low = 0xA;
    high = 0;
    while (high <= 0x6) : (high += 1) {
        if (high % 2 == 0) arr[high << 4 | low] = .Accumulator;
    }

    // Absolute and X absolute
    arr[0x2 << 4 | 0xC] = .Absolute;
    arr[0x4 << 4 | 0xC] = .Absolute;
    arr[0x8 << 4 | 0xC] = .Absolute;
    arr[0xA << 4 | 0xC] = .Absolute;
    arr[0xC << 4 | 0xC] = .Absolute;
    arr[0xE << 4 | 0xC] = .Absolute;
    arr[0xB << 4 | 0xC] = .AbsoluteX;

    // Indirect
    arr[0x6 << 4 | 0xC] = .Indirect;

    // Absolute and X absolute
    low = 0xD;
    high = 0;
    while (high <= 0xF) : (high += 1) {
        if (high % 2 == 0) {
            arr[high << 4 | low] = .Absolute;
        } else {
            arr[high << 4 | low] = .AbsoluteX;
        }
    }

    // Absolute Y absolute and X absolute
    low = 0xE;
    high = 0;
    while (high <= 0xF) : (high += 1) {
        if (high % 2 == 0) {
            arr[high << 4 | low] = .Absolute;
        } else {
            arr[high << 4 | low] = .AbsoluteX;
        }
    }

    break :init arr;
};

pub const opcode = init: {
    var arr = [_]Opcode{.ADC} ** 32;

    arr[0b011 << 3 | 0b01] = .ADC;

    break :init arr;
};
