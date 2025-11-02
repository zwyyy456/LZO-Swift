enum LZOConstants {
    static let m1_MAX_OFFSET = 0x0400
    static let m2_MAX_OFFSET = 0x0800
    static let m3_MAX_OFFSET = 0x4000
    static let m4_MAX_OFFSET = 0xbfff
    static let mX_MAX_OFFSET = m1_MAX_OFFSET + m2_MAX_OFFSET

    static let m1_MIN_LEN = 2
    static let m1_MAX_LEN = 2
    static let m2_MIN_LEN = 3
    static let m2_MAX_LEN = 8
    static let m3_MIN_LEN = 3
    static let m3_MAX_LEN = 33
    static let m4_MIN_LEN = 3
    static let m4_MAX_LEN = 9

    static let m1_MARKER: Int = 0
    static let m2_MARKER: Int = 64
    static let m3_MARKER: Int = 32
    static let m4_MARKER: Int = 16

    static let d_BITS = 14
    static let d_MASK = (1 << d_BITS) - 1
    static let d_HIGH = (d_MASK >> 1) + 1
}
