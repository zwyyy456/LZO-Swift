struct LZOByteReader {
    let bytes: [UInt8]
    private(set) var index: Int = 0

    init(bytes: [UInt8]) {
        self.bytes = bytes
    }

    mutating func readU8() throws -> UInt8 {
        guard index < bytes.count else {
            throw LZOError.inputUnderrun
        }
        let value = bytes[index]
        index += 1
        return value
    }

    mutating func readU16() throws -> Int {
        let low = Int(try readU8())
        let high = Int(try readU8())
        return low | (high << 8)
    }

    mutating func readAppend(count: Int, to out: inout [UInt8]) throws {
        guard count >= 0 else {
            return
        }
        guard index + count <= bytes.count else {
            throw LZOError.inputUnderrun
        }
        out.append(contentsOf: bytes[index ..< index + count])
        index += count
    }

    mutating func readMulti(base: Int) throws -> Int {
        var total = 0
        while true {
            let value = try readU8()
            if value == 0 {
                total += 255
            } else {
                total += Int(value) + base
                return total
            }
        }
    }
}
