import Foundation

public struct LZO {
    /// Compresses the given buffer with the LZO1X (fast) algorithm.
    /// - Parameter data: Plain input payload.
    /// - Returns: Compressed bytes, terminated with the standard LZO end marker.
    public static func compress1X(_ data: Data) -> Data {
        let bytes = [UInt8](data)
        let compressed = LZOCompressor.compress1X(bytes)
        return Data(compressed)
    }

    /// Compresses the given buffer with the LZO1X (fast) algorithm.
    /// - Parameter input: Plain input payload.
    /// - Returns: Compressed bytes, terminated with the standard LZO end marker.
    public static func compress1X(_ input: [UInt8]) -> [UInt8] {
        LZOCompressor.compress1X(input)
    }

    /// Decompresses an LZO1X buffer.
    /// - Parameter data: Payload previously produced by `compress1X`.
    /// - Throws: `LZOError` when the input stream is truncated or self-inconsistent.
    public static func decompress1X(_ data: Data) throws -> Data {
        let bytes = [UInt8](data)
        let decompressed = try LZODecompressor.decompress1X(bytes)
        return Data(decompressed)
    }

    /// Decompresses an LZO1X buffer.
    /// - Parameter input: Payload previously produced by `compress1X`.
    /// - Throws: `LZOError` when the input stream is truncated or self-inconsistent.
    public static func decompress1X(_ input: [UInt8]) throws -> [UInt8] {
        try LZODecompressor.decompress1X(input)
    }
}
