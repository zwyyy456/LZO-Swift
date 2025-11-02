import Foundation
import Testing
@testable import LZO

@Suite("LZO1X Compression")
struct LZOTests {
    @Test("Fixture bytes match compressor output for test_a and test_b")
    func fixtureBytesMatchShortStrings() throws {
        let fixtures: [(name: String, plain: String)] = [
            ("test_a", "fixture-a-output"),
            ("test_b", "fixture-b-output-with-newline\n")
        ]

        for fixture in fixtures {
            let fileBytes = try fixtureBytes(named: fixture.name)
            let compressed = LZO.compress1X(Array(fixture.plain.utf8))
            guard fileBytes == compressed else {
                print("Fixture \(fixture.name) file bytes:", fileBytes)
                print("Fixture \(fixture.name) recompressed bytes:", compressed)
                #expect(fileBytes == compressed, "Compressed payload for \(fixture.name) does not match reference file bytes")
                return
            }
        }
    }

    @Test("Fixture bytes match compressor output for test_c")
    func fixtureBytesMatchLongString() throws {
        let fileBytes = try fixtureBytes(named: "test_c")
        let compressed = LZO.compress1X(Array("fixture-c-contains-binary-data".utf8))
        guard fileBytes == compressed else {
            print("Fixture test_c file bytes:", fileBytes)
            print("Fixture test_c recompressed bytes:", compressed)
            #expect(fileBytes == compressed, "Compressed payload for test_c does not match reference file bytes")
            return
        }
    }

    @Test("Decompressed fixture payloads match reference strings")
    func fixtureDecompressMatchesPlaintext() throws {
        let fixtures: [(name: String, plain: String)] = [
            ("test_a", "fixture-a-output"),
            ("test_b", "fixture-b-output-with-newline\n"),
            ("test_c", "fixture-c-contains-binary-data")
        ]

        for fixture in fixtures {
            let fileBytes = try fixtureBytes(named: fixture.name)
            let decompressed = try LZO.decompress1X(fileBytes)
            let expected = Array(fixture.plain.utf8)
            guard decompressed == expected else {
                print("Fixture \(fixture.name) decompressed bytes:", decompressed)
                print("Fixture \(fixture.name) expected bytes:", expected)
                #expect(decompressed == expected, "Decompressed payload for \(fixture.name) does not match expected bytes")
                return
            }
        }
    }

    @Test("Roundtrip with short literal payload")
    func roundTripShort() throws {
        let payload = Array("hello lzo!".utf8)
        let compressed = LZO.compress1X(payload)
        #expect(!compressed.isEmpty, "Compression should produce data")

        let decompressed = try LZO.decompress1X(compressed)
        #expect(decompressed == payload)
    }

    @Test("Roundtrip with repeating data longer than dictionary window")
    func roundTripRepeating() throws {
        let pattern = Array("abcdefghijklmnopqrstuvwxyz".utf8)
        let payload = Array(repeating: pattern, count: 64).flatMap { $0 }

        let compressed = LZO.compress1X(payload)
        let decompressed = try LZO.decompress1X(compressed)

        #expect(decompressed == payload)
        #expect(compressed.count < payload.count, "Compressed output should be smaller for repeating data")
    }

    @Test("Throws on truncated input stream")
    func truncatedInputFails() throws {
        let payload = Array("truncated input check for lzo".utf8)
        let compressed = LZO.compress1X(payload)
        #expect(!compressed.isEmpty)

        for trim in 1...min(8, compressed.count - 1) {
            let truncated = Array(compressed.dropLast(trim))
            #expect(throws: LZOError.inputUnderrun) {
                _ = try LZO.decompress1X(truncated)
            }
        }
    }

    @Test("Handles zero-length payload")
    func emptyPayload() throws {
        let payload: [UInt8] = []
        let compressed = LZO.compress1X(payload)
        let decompressed = try LZO.decompress1X(compressed)
        #expect(decompressed == payload)
    }

    private func fixtureBytes(named name: String) throws -> [UInt8] {
        let possibleExtensions = ["lzo", "txt"]
        for ext in possibleExtensions {
            if let url = Bundle.module.url(forResource: name, withExtension: ext) {
                let data = try Data(contentsOf: url)
                return Array(data)
            }
        }
        let candidates = possibleExtensions.map { "\(name).\($0)" }.joined(separator: ", ")
        struct FixtureError: Error, CustomStringConvertible {
            let description: String
        }
        throw FixtureError(description: "Missing test resource: \(candidates)")
    }
}
