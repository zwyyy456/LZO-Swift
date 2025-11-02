struct LZODecompressor {
    static func decompress1X(_ input: [UInt8]) throws -> [UInt8] {
        var reader = LZOByteReader(bytes: input)
        var out: [UInt8] = []
        var last2: UInt8 = 0

        var ip = try reader.readU8()

        if ip > 17 {
            var t = Int(ip) - 17
            if t < 4 {
                if t > 0 {
                    try reader.readAppend(count: t, to: &out)
                }
                ip = try reader.readU8()
                if let next = try decodeMatch(initial: ip, reader: &reader, out: &out, last2: &last2) {
                    ip = next
                } else {
                    return out
                }
            } else {
                try reader.readAppend(count: t, to: &out)
                ip = try reader.readU8()
                last2 = ip
                t = Int(ip)
                if t >= 16 {
                    if let next = try decodeMatch(initial: ip, reader: &reader, out: &out, last2: &last2) {
                        ip = next
                    } else {
                        return out
                    }
                } else {
                    var mPos = out.count - (1 + LZOConstants.m2_MAX_OFFSET)
                    mPos -= t >> 2
                    let b = try reader.readU8()
                    mPos -= Int(b) << 2
                    if mPos < 0 {
                        throw LZOError.lookBehindUnderrun
                    }
                    try copyMatch(out: &out, from: mPos, length: 3)
                    if let next = try finishMatch(reader: &reader, out: &out, last2: &last2) {
                        ip = next
                    } else {
                        return out
                    }
                }
            }
        }

        while true {
            let t0 = Int(ip)
            if t0 >= 16 {
                if let next = try decodeMatch(initial: ip, reader: &reader, out: &out, last2: &last2) {
                    ip = next
                    continue
                } else {
                    return out
                }
            }

            var t = t0
            if t == 0 {
                t = try reader.readMulti(base: 15)
            }
            try reader.readAppend(count: t + 3, to: &out)

            ip = try reader.readU8()
            last2 = ip
            t = Int(ip)
            if t >= 16 {
                if let next = try decodeMatch(initial: ip, reader: &reader, out: &out, last2: &last2) {
                    ip = next
                    continue
                } else {
                    return out
                }
            }

            var mPos = out.count - (1 + LZOConstants.m2_MAX_OFFSET)
            mPos -= t >> 2
            let b = try reader.readU8()
            mPos -= Int(b) << 2
            if mPos < 0 {
                throw LZOError.lookBehindUnderrun
            }
            try copyMatch(out: &out, from: mPos, length: 3)

            if let next = try finishMatch(reader: &reader, out: &out, last2: &last2) {
                ip = next
            } else {
                return out
            }
        }
    }

    private static func finishMatch(reader: inout LZOByteReader,
                                    out: inout [UInt8],
                                    last2: inout UInt8) throws -> UInt8? {
        let extra = Int(last2 & 3)
        if extra == 0 {
            return try reader.readU8()
        }
        try reader.readAppend(count: extra, to: &out)
        let next = try reader.readU8()
        return try decodeMatch(initial: next, reader: &reader, out: &out, last2: &last2)
    }

    private static func decodeMatch(initial ip: UInt8,
                                    reader: inout LZOByteReader,
                                    out: inout [UInt8],
                                    last2: inout UInt8) throws -> UInt8? {
        var ip = ip
        while true {
            var t = Int(ip)
            last2 = ip

            if t >= 64 {
                var mPos = out.count - 1
                mPos -= (t >> 2) & 7
                let b = try reader.readU8()
                mPos -= Int(b) << 3
                if mPos < 0 {
                    throw LZOError.lookBehindUnderrun
                }
                t = (t >> 5) - 1
                try copyMatch(out: &out, from: mPos, length: t + 2)
            } else if t >= 32 {
                t &= 31
                if t == 0 {
                    t = try reader.readMulti(base: 31)
                }
                var mPos = out.count - 1
                let v16 = try reader.readU16()
                mPos -= v16 >> 2
                last2 = UInt8(truncatingIfNeeded: v16 & 0xFF)
                if mPos < 0 {
                    throw LZOError.lookBehindUnderrun
                }
                try copyMatch(out: &out, from: mPos, length: t + 2)
            } else if t >= 16 {
                var mPos = out.count
                mPos -= (t & 8) << 11
                t &= 7
                if t == 0 {
                    t = try reader.readMulti(base: 7)
                }
                let v16 = try reader.readU16()
                mPos -= v16 >> 2
                if mPos == out.count {
                    return nil
                }
                mPos -= 0x4000
                last2 = UInt8(truncatingIfNeeded: v16 & 0xFF)
                if mPos < 0 {
                    throw LZOError.lookBehindUnderrun
                }
                try copyMatch(out: &out, from: mPos, length: t + 2)
            } else {
                var mPos = out.count - 1
                mPos -= t >> 2
                let b = try reader.readU8()
                mPos -= Int(b) << 2
                if mPos < 0 {
                    throw LZOError.lookBehindUnderrun
                }
                try copyMatch(out: &out, from: mPos, length: 2)
            }

            let extra = Int(last2 & 3)
            if extra == 0 {
                return try reader.readU8()
            }
            try reader.readAppend(count: extra, to: &out)
            ip = try reader.readU8()
        }
    }

    private static func copyMatch(out: inout [UInt8], from position: Int, length: Int) throws {
        if position < 0 {
            throw LZOError.lookBehindUnderrun
        }
        if position + length <= out.count {
            out.append(contentsOf: out[position ..< position + length])
        } else {
            var src = position
            for _ in 0..<length {
                guard src < out.count else {
                    throw LZOError.lookBehindUnderrun
                }
                out.append(out[src])
                src += 1
            }
        }
    }
}
