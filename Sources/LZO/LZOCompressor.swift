struct LZOCompressor {
    static func compress1X(_ input: [UInt8]) -> [UInt8] {
        var output: [UInt8] = []
        var trailing = 0
        let inLen = input.count

        if inLen <= LZOConstants.m2_MAX_LEN + 5 {
            trailing = inLen
        } else {
            let result = compressCore(input)
            output = result.out
            trailing = result.trailing
        }

        if trailing > 0 {
            let start = inLen - trailing
            if output.isEmpty && trailing <= 238 {
                output.append(UInt8(17 + trailing))
            } else if trailing <= 3 {
                if output.count >= 2 {
                    output[output.count - 2] |= UInt8(trailing)
                } else {
                    output.append(UInt8(17 + trailing))
                }
            } else if trailing <= 18 {
                output.append(UInt8(trailing - 3))
            } else {
                output.append(0)
                appendMulti(&output, trailing - 18)
            }
            output.append(contentsOf: input[start ..< start + trailing])
        }

        output.append(UInt8(LZOConstants.m4_MARKER | 1))
        output.append(0)
        output.append(0)
        return output
    }

    private static func compressCore(_ input: [UInt8]) -> (out: [UInt8], trailing: Int) {
        var out: [UInt8] = []
        let inLen = input.count
        let ipLimit = inLen - LZOConstants.m2_MAX_LEN - 5
        var dict = [Int32](repeating: 0, count: 1 << LZOConstants.d_BITS)
        var ii = 0
        var ip = 4
        var mOff = 0

        while ip < ipLimit {
            var key = Int(input[ip + 3])
            key = (key << 6) ^ Int(input[ip + 2])
            key = (key << 5) ^ Int(input[ip + 1])
            key = (key << 5) ^ Int(input[ip + 0])
            var dIndex = ((0x21 * key) >> 5) & LZOConstants.d_MASK
            var mPos = Int(dict[dIndex]) - 1

            var matched = false

            if mPos >= 0,
               mPos + 3 < inLen,
               ip != mPos,
               (ip - mPos) <= LZOConstants.m4_MAX_OFFSET {
                mOff = ip - mPos
                if mOff <= LZOConstants.m2_MAX_OFFSET || input[mPos + 3] == input[ip + 3] {
                    matched = input[mPos] == input[ip]
                        && input[mPos + 1] == input[ip + 1]
                        && input[mPos + 2] == input[ip + 2]
                }
            }

            if !matched {
                let altIndex = (dIndex & (LZOConstants.d_MASK & 0x7ff)) ^ (LZOConstants.d_HIGH | 0x1f)
                let altPos = Int(dict[altIndex]) - 1
                if altPos >= 0,
                   altPos + 3 < inLen,
                   ip != altPos,
                   (ip - altPos) <= LZOConstants.m4_MAX_OFFSET {
                    let altOff = ip - altPos
                    if altOff <= LZOConstants.m2_MAX_OFFSET || input[altPos + 3] == input[ip + 3] {
                        if input[altPos] == input[ip],
                           input[altPos + 1] == input[ip + 1],
                           input[altPos + 2] == input[ip + 2] {
                            matched = true
                            mPos = altPos
                            mOff = altOff
                            dIndex = altIndex
                        }
                    }
                }
            } else {
                dict[dIndex] = Int32(ip + 1)
            }

            if !matched {
                dict[dIndex] = Int32(ip + 1)
                ip += 1 + ((ip - ii) >> 5)
                continue
            }

            dict[dIndex] = Int32(ip + 1)

            if ip != ii {
                let t = ip - ii
                if t <= 3 {
                    if out.count >= 2 {
                        out[out.count - 2] |= UInt8(t)
                    } else {
                        out.append(UInt8(17 + t))
                    }
                } else if t <= 18 {
                    out.append(UInt8(t - 3))
                } else {
                    out.append(0)
                    appendMulti(&out, t - 18)
                }
                out.append(contentsOf: input[ii ..< ii + t])
                ii += t
            }

            var i = 3
            ip += 3
            while i < 9,
                  (mPos + i) < inLen,
                  (ip - 1) < inLen {
                ip += 1
                if input[mPos + i] != input[ip - 1] {
                    break
                }
                i += 1
            }

            if i < 9 {
                ip -= 1
                let mLen = ip - ii
                if mOff <= LZOConstants.m2_MAX_OFFSET {
                    var offset = mOff - 1
                    let first = ((mLen - 1) << 5) | ((offset & 7) << 2)
                    out.append(UInt8(truncatingIfNeeded: first))
                    out.append(UInt8(truncatingIfNeeded: offset >> 3))
                } else if mOff <= LZOConstants.m3_MAX_OFFSET {
                    var offset = mOff - 1
                    out.append(UInt8(truncatingIfNeeded: LZOConstants.m3_MARKER | (mLen - 2)))
                    out.append(UInt8(truncatingIfNeeded: (offset & 63) << 2))
                    out.append(UInt8(truncatingIfNeeded: offset >> 6))
                } else {
                    var offset = mOff - 0x4000
                    let marker = LZOConstants.m4_MARKER | ((offset & 0x4000) >> 11) | (mLen - 2)
                    out.append(UInt8(truncatingIfNeeded: marker))
                    out.append(UInt8(truncatingIfNeeded: (offset & 63) << 2))
                    out.append(UInt8(truncatingIfNeeded: offset >> 6))
                }
            } else {
                var m = mPos + LZOConstants.m2_MAX_LEN + 1
                while ip < inLen,
                      m < inLen,
                      input[m] == input[ip] {
                    m += 1
                    ip += 1
                }
                let mLen = ip - ii
                if mOff <= LZOConstants.m3_MAX_OFFSET {
                    var offset = mOff - 1
                    if mLen <= 33 {
                        out.append(UInt8(truncatingIfNeeded: LZOConstants.m3_MARKER | (mLen - 2)))
                    } else {
                        var len = mLen - 33
                        out.append(UInt8(truncatingIfNeeded: LZOConstants.m3_MARKER | 0))
                        appendMulti(&out, len)
                    }
                    out.append(UInt8(truncatingIfNeeded: (offset & 63) << 2))
                    out.append(UInt8(truncatingIfNeeded: offset >> 6))
                } else {
                    var offset = mOff - 0x4000
                    if mLen <= LZOConstants.m4_MAX_LEN {
                        out.append(UInt8(truncatingIfNeeded: LZOConstants.m4_MARKER | ((offset & 0x4000) >> 11) | (mLen - 2)))
                    } else {
                        var len = mLen - LZOConstants.m4_MAX_LEN
                        out.append(UInt8(truncatingIfNeeded: LZOConstants.m4_MARKER | ((offset & 0x4000) >> 11)))
                        appendMulti(&out, len)
                    }
                    out.append(UInt8(truncatingIfNeeded: (offset & 63) << 2))
                    out.append(UInt8(truncatingIfNeeded: offset >> 6))
                }
            }

            ii = ip
        }

        let trailing = inLen - ii
        return (out, trailing)
    }

    private static func appendMulti(_ out: inout [UInt8], _ value: Int) {
        var t = value
        while t > 255 {
            out.append(0)
            t -= 255
        }
        out.append(UInt8(truncatingIfNeeded: t))
    }
}
