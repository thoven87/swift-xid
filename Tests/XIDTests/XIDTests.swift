import Foundation
import Testing

@testable import SwiftXID

/// Comprehensive test suite for XID implementation using Swift Testing
@Suite("XID Tests")
struct XIDTests {

  // MARK: - Basic Generation Tests

  @Test("XID generation creates correct format")
  func xidGeneration() {
    let xid = XID()
    #expect(xid.data.count == 12, "XID should be exactly 12 bytes")
    #expect(xid.string.count == 20, "XID string should be exactly 20 characters")
  }

  @Test("XID generation with timestamp")
  func xidGenerationWithTimestamp() {
    let timestamp = Date(timeIntervalSince1970: 1_234_567_890)
    let xid = XID(timestamp: timestamp)

    #expect(abs(xid.timestamp.timeIntervalSince1970 - 1_234_567_890) < 1.0)
    #expect(xid.data.count == 12)
  }

  @Test("Multiple XIDs are unique")
  func multipleXIDsAreUnique() {
    let xids = (0..<1000).map { _ in XID() }
    let uniqueXIDs = Set(xids)
    #expect(xids.count == uniqueXIDs.count, "All generated XIDs should be unique")
  }

  // MARK: - Sorting Tests

  @Test("XIDs sort by time")
  func xidsSortByTime() async {
    var xids: [XID] = []

    // Generate XIDs with small delays to ensure different timestamps
    for _ in 0..<10 {
      xids.append(XID())
      try? await Task.sleep(for: .milliseconds(1))
    }

    let sortedXIDs = xids.sorted()

    // Verify they're in chronological order
    for i in 0..<(sortedXIDs.count - 1) {
      #expect(
        sortedXIDs[i].timestamp <= sortedXIDs[i + 1].timestamp,
        "XIDs should be sortable by generation time"
      )
    }
  }

  @Test("XID comparison")
  func xidComparison() async {
    let xid1 = XID()
    try? await Task.sleep(for: .milliseconds(1))
    let xid2 = XID()

    #expect(xid1 < xid2, "Earlier XID should be less than later XID")
    #expect(xid2 > xid1, "Later XID should be greater than earlier XID")
  }

  // MARK: - String Encoding/Decoding Tests

  @Test("String round trip")
  func stringRoundTrip() throws {
    let original = XID()
    let encoded = original.string
    let decoded = try XID(string: encoded)

    #expect(original == decoded, "XID should survive string round-trip")
    #expect(original.data == decoded.data, "Data should be identical after round-trip")
  }

  @Test("String is URL safe")
  func stringIsURLSafe() {
    let xid = XID()
    let string = xid.string

    // Check that string only contains URL-safe characters
    let urlSafeCharacters = CharacterSet.alphanumerics
    let stringCharacters = CharacterSet(charactersIn: string)

    #expect(
      urlSafeCharacters.isSuperset(of: stringCharacters),
      "XID string should only contain URL-safe characters"
    )

    // Should not contain problematic characters
    #expect(!string.contains("/"))
    #expect(!string.contains("+"))
    #expect(!string.contains("="))
  }

  @Test(
    "Invalid string throws error",
    arguments: [
      "invalid",
      "too-short",
      "way-too-long-string-here",
      "invalid!@#$%^&*()chars",
    ])
  func invalidStringThrows(invalidString: String) {
    #expect(throws: XIDError.invalidString) {
      try XID(string: invalidString)
    }
  }

  // MARK: - Data Tests

  @Test("Data round trip")
  func dataRoundTrip() throws {
    let original = XID()
    let data = original.data
    let fromData = try XID(data: data)

    #expect(original == fromData, "XID should survive data round-trip")
  }

  @Test("Invalid data length throws error")
  func invalidDataLengthThrows() {
    let shortData = Data([1, 2, 3])
    let longData = Data(repeating: 0, count: 20)

    #expect(throws: XIDError.invalidLength) {
      try XID(data: shortData)
    }

    #expect(throws: XIDError.invalidLength) {
      try XID(data: longData)
    }
  }

  // MARK: - Component Tests

  @Test("Timestamp component")
  func timestampComponent() {
    let timestamp = Date(timeIntervalSince1970: 1_600_000_000)
    let xid = XID(timestamp: timestamp)

    #expect(
      abs(xid.timestamp.timeIntervalSince1970 - 1_600_000_000) < 1.0,
      "Timestamp should be preserved in XID"
    )
  }

  @Test("Machine ID component consistency")
  func machineIDComponent() {
    let xid1 = XID()
    let xid2 = XID()

    // Same machine should have same machine ID
    #expect(xid1.machineID == xid2.machineID, "Machine ID should be consistent")
    #expect(xid1.machineID.count == 3, "Machine ID should be 3 bytes")
  }

  @Test("Process ID component consistency")
  func processIDComponent() {
    let xid1 = XID()
    let xid2 = XID()

    // Same process should have same process ID
    #expect(xid1.processID == xid2.processID, "Process ID should be consistent")
  }

  @Test("Counter behavior")
  func counterBehavior() {
    let xids = (0..<10).map { _ in XID() }

    // All counters should be within reasonable range
    for xid in xids {
      #expect(xid.counter <= 0xFFFFFF, "Counter should not exceed 24-bit range")
    }
  }

  // MARK: - Codable Tests

  @Test("JSON encoding round trip")
  func jsonEncoding() throws {
    let xid = XID()
    let jsonData = try JSONEncoder().encode(xid)
    let decoded = try JSONDecoder().decode(XID.self, from: jsonData)

    #expect(xid == decoded, "XID should survive JSON round-trip")
  }

  @Test("JSON encoding format")
  func jsonEncodingFormat() throws {
    let xid = XID()
    let jsonData = try JSONEncoder().encode(xid)
    let jsonString = String(data: jsonData, encoding: .utf8)!

    // Should be encoded as a quoted string
    #expect(jsonString.hasPrefix("\""))
    #expect(jsonString.hasSuffix("\""))
    #expect(jsonString.count == 22)  // 20 chars + 2 quotes
  }

  // MARK: - Equality and Hashing Tests

  @Test("Equality behavior")
  func equality() {
    let xid1 = XID()
    let xid2 = xid1  // Same instance
    let xid3 = XID()  // Different instance

    #expect(xid1 == xid2, "Same XID should be equal to itself")
    #expect(xid1 != xid3, "Different XIDs should not be equal")
  }

  @Test("Hashing behavior")
  func hashing() {
    let xid1 = XID()
    let xid2 = XID()

    let set = Set([xid1, xid2])
    #expect(set.count == 2, "Different XIDs should hash differently")

    // Same XID should hash the same
    let duplicateSet = Set([xid1, xid1])
    #expect(duplicateSet.count == 1, "Same XID should hash identically")
  }

  // MARK: - Concurrency Tests

  @Test("Concurrent generation produces unique XIDs")
  func concurrentGeneration() async {
    let allXIDs = await withTaskGroup(of: [XID].self, returning: [XID].self) { group in
      // Generate XIDs concurrently from multiple tasks
      for _ in 0..<10 {
        group.addTask {
          return (0..<100).map { _ in XID() }
        }
      }

      var result: [XID] = []
      for await xids in group {
        result.append(contentsOf: xids)
      }
      return result
    }

    let uniqueXIDs = Set(allXIDs)
    #expect(
      allXIDs.count == uniqueXIDs.count,
      "All concurrently generated XIDs should be unique"
    )
  }

  // MARK: - Edge Cases

  @Test("Zero timestamp")
  func zeroTimestamp() {
    let zeroTimestamp = Date(timeIntervalSince1970: 0)
    let xid = XID(timestamp: zeroTimestamp)

    #expect(abs(xid.timestamp.timeIntervalSince1970 - 0) < 1.0)
    #expect(xid.data.count == 12)
  }

  @Test("Future timestamp")
  func futureTimestamp() {
    let futureTimestamp = Date(timeIntervalSince1970: 4_000_000_000)  // Year 2096
    let xid = XID(timestamp: futureTimestamp)

    #expect(abs(xid.timestamp.timeIntervalSince1970 - 4_000_000_000) < 1.0)
    #expect(xid.data.count == 12)
  }

  @Test("CustomStringConvertible implementation")
  func customStringConvertible() {
    let xid = XID()
    let description = String(describing: xid)

    #expect(description == xid.string, "Description should match string representation")
    #expect(description.count == 20, "Description should be 20 characters")
  }

  @Test("Sendable compliance")
  func sendableCompliance() async {
    let xid = XID()

    // Test that XID can be sent across concurrency boundaries
    let result = await withTaskGroup(of: XID.self, returning: XID.self) { group in
      group.addTask {
        return xid
      }

      var result: XID? = nil
      for await taskResult in group {
        result = taskResult
        break
      }
      return result!
    }

    #expect(result == xid, "XID should be sendable across task boundaries")
  }
}

// MARK: - Performance Tests

@Suite("XID Performance Tests")
struct XIDPerformanceTests {

  @Test("Generation performance", .timeLimit(.minutes(1)))
  func generationPerformance() {
    let startTime = ContinuousClock.now

    for _ in 0..<10_000 {
      _ = XID()
    }

    let timeElapsed = ContinuousClock.now - startTime
    #expect(timeElapsed < .seconds(1), "Should generate 10,000 XIDs in under 1 second")
  }

  @Test("String encoding performance", .timeLimit(.minutes(1)))
  func stringEncodingPerformance() {
    let xids = (0..<1000).map { _ in XID() }

    let startTime = ContinuousClock.now

    for xid in xids {
      _ = xid.string
    }

    let timeElapsed = ContinuousClock.now - startTime
    #expect(
      timeElapsed < .milliseconds(100),
      "Should encode 1,000 XIDs to strings in under 0.1 seconds")
  }

  @Test("String decoding performance", .timeLimit(.minutes(1)))
  func stringDecodingPerformance() throws {
    let strings = (0..<1000).map { _ in XID().string }

    let startTime = ContinuousClock.now

    for string in strings {
      _ = try! XID(string: string)
    }

    let timeElapsed = ContinuousClock.now - startTime
    #expect(
      timeElapsed < .milliseconds(100), "Should decode 1,000 XID strings in under 0.1 seconds"
    )
  }
}
