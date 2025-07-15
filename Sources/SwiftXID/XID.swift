import Foundation
import Synchronization

/// A globally unique identifier that is sortable and URL-safe.
///
/// XID is a 12-byte globally unique id with the following format:
/// - 4-byte timestamp (seconds since Unix epoch)
/// - 3-byte machine identifier
/// - 2-byte process identifier
/// - 3-byte counter
///
/// XIDs are lexicographically sortable by generation time and are URL-safe when encoded.
///
/// ## Example Usage
///
/// ```swift
/// // Generate a new XID
/// let id = XID()
/// print(id.string) // "c3h6k27d0000000000"
///
/// // Parse from string
/// let parsed = try XID(string: "c3h6k27d0000000000")
///
/// // Compare XIDs (sortable by time)
/// let id1 = XID()
/// try? await Task.sleep(for: .milliseconds(1))
/// let id2 = XID()
/// print(id1 < id2) // true
/// ```
public struct XID: Sendable {
    /// The raw 12-byte data of the XID
    public let data: Data

    /// Thread-safe counter for generating unique XIDs
    private static let counter = Mutex<UInt32>(UInt32.random(in: 0...0xFFFFFF))

    /// Cached machine ID derived from hostname
    private static let machineID: Data = {
        let hostname = ProcessInfo.processInfo.hostName
        let data = Data(hostname.utf8)

        // Simple hash function (djb2 algorithm)
        var hash: UInt32 = 5381
        for byte in data {
            hash = ((hash << 5) &+ hash) &+ UInt32(byte)
        }

        // Convert to 3 bytes
        var hashBytes = hash.bigEndian
        let hashData = Data(bytes: &hashBytes, count: 4)
        return Data(hashData.prefix(3))
    }()

    /// Cached process ID
    private static let processID = UInt16(ProcessInfo.processInfo.processIdentifier & 0xFFFF)

    /// Creates a new XID with the current timestamp
    public init() {
        self.init(timestamp: Date())
    }

    /// Creates a new XID with the specified timestamp
    /// - Parameter timestamp: The timestamp to encode in the XID
    public init(timestamp: Date) {
        let unixTime = UInt32(timestamp.timeIntervalSince1970)
        let counter = Self.counter.withLock { counter in
            counter = (counter + 1) & 0xFFFFFF
            return counter
        }

        var data = Data(capacity: 12)

        // 4-byte timestamp (big-endian)
        var time = unixTime.bigEndian
        data.append(Data(bytes: &time, count: 4))

        // 3-byte machine ID
        data.append(Self.machineID)

        // 2-byte process ID
        var pid = Self.processID.bigEndian
        data.append(Data(bytes: &pid, count: 2))

        // 3-byte counter (big-endian)
        var counterBytes = counter.bigEndian
        let counterData = Data(bytes: &counterBytes, count: 4)
        data.append(counterData.suffix(3))  // Take last 3 bytes

        self.data = data
    }

    /// Creates an XID from raw 12-byte data
    /// - Parameter data: The raw 12-byte XID data
    /// - Throws: `XIDError.invalidLength` if data is not exactly 12 bytes
    public init(data: Data) throws {
        guard data.count == 12 else {
            throw XIDError.invalidLength
        }
        self.data = data
    }

    /// Creates an XID from a base32-encoded string
    /// - Parameter string: The base32-encoded XID string (20 characters)
    /// - Throws: `XIDError.invalidString` if the string cannot be decoded
    public init(string: String) throws {
        guard let data = Self.decode(string: string) else {
            throw XIDError.invalidString
        }
        self.data = data
    }

    /// The timestamp component of the XID
    public var timestamp: Date {
        let timeBytes = data.prefix(4)
        let unixTime = timeBytes.withUnsafeBytes { bytes in
            UInt32(bigEndian: bytes.load(as: UInt32.self))
        }
        return Date(timeIntervalSince1970: TimeInterval(unixTime))
    }

    /// The machine ID component of the XID
    public var machineID: Data {
        data.subdata(in: 4..<7)
    }

    /// The process ID component of the XID
    public var processID: UInt16 {
        let pidBytes = data.subdata(in: 7..<9)
        return pidBytes.withUnsafeBytes { bytes in
            UInt16(bigEndian: bytes.load(as: UInt16.self))
        }
    }

    /// The counter component of the XID
    public var counter: UInt32 {
        let counterBytes = data.suffix(3)
        let fullCounter = Data([0]) + counterBytes  // Pad to 4 bytes
        return fullCounter.withUnsafeBytes { bytes in
            UInt32(bigEndian: bytes.load(as: UInt32.self))
        }
    }

    /// Base32-encoded string representation of the XID
    public var string: String {
        Self.encode(data: data)
    }

    /// Base32 alphabet for XID encoding (Crockford's Base32)
    private static let base32Alphabet = "0123456789abcdefghjkmnpqrstvwxyz"

    /// Encodes data to base32 string using XID's alphabet
    private static func encode(data: Data) -> String {
        let alphabet = Array(base32Alphabet)
        var result = ""
        result.reserveCapacity(20)

        let bytes = Array(data)
        var bitBuffer: UInt64 = 0
        var bitsInBuffer = 0

        for byte in bytes {
            bitBuffer = (bitBuffer << 8) | UInt64(byte)
            bitsInBuffer += 8

            while bitsInBuffer >= 5 {
                let index = Int((bitBuffer >> (bitsInBuffer - 5)) & 0x1F)
                result.append(alphabet[index])
                bitsInBuffer -= 5
            }
        }

        // Handle remaining bits
        if bitsInBuffer > 0 {
            let index = Int((bitBuffer << (5 - bitsInBuffer)) & 0x1F)
            result.append(alphabet[index])
        }

        return result
    }

    /// Decodes base32 string to data using XID's alphabet
    private static func decode(string: String) -> Data? {
        guard string.count == 20 else { return nil }

        let charMap: [Character: UInt8] = Dictionary(
            uniqueKeysWithValues:
                base32Alphabet.enumerated().map { ($0.element, UInt8($0.offset)) })

        var result = Data()
        result.reserveCapacity(12)

        let chars = Array(string.lowercased())
        var bitBuffer: UInt64 = 0
        var bitsInBuffer = 0

        for char in chars {
            guard let value = charMap[char] else { return nil }

            bitBuffer = (bitBuffer << 5) | UInt64(value)
            bitsInBuffer += 5

            if bitsInBuffer >= 8 {
                let byte = UInt8((bitBuffer >> (bitsInBuffer - 8)) & 0xFF)
                result.append(byte)
                bitsInBuffer -= 8
            }
        }

        return result.count == 12 ? result : nil
    }
}

// MARK: - Conformances

extension XID: Equatable {
    public static func == (lhs: XID, rhs: XID) -> Bool {
        lhs.data == rhs.data
    }
}

extension XID: Comparable {
    /// XIDs are compared lexicographically, making them sortable by generation time
    public static func < (lhs: XID, rhs: XID) -> Bool {
        lhs.data.lexicographicallyPrecedes(rhs.data)
    }
}

extension XID: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(data)
    }
}

extension XID: CustomStringConvertible {
    public var description: String {
        string
    }
}

extension XID: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        try self.init(string: string)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(string)
    }
}

// MARK: - Errors

/// Errors that can occur when working with XIDs
public enum XIDError: Error, LocalizedError {
    /// The provided data is not exactly 12 bytes
    case invalidLength
    /// The provided string cannot be decoded as an XID
    case invalidString

    public var errorDescription: String? {
        switch self {
        case .invalidLength:
            return "XID data must be exactly 12 bytes"
        case .invalidString:
            return "Invalid XID string format"
        }
    }
}
