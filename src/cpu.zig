pub const MEM_SIZE = 65535;
pub const CPU = struct {
    pc: u16,
    ac: u8,
    x: u8,
    y: u8,
    sr: u8,
    // Flags
    neg: u1,
    overflow: u1,
    brk: u1,
    dec: u1,
    int: u1,
    zero: u1,
    carry: u1,
};
