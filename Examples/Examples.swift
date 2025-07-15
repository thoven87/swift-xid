import Foundation
import SwiftXID

/// Examples demonstrating various XID usage patterns
enum Examples {

    /// Basic XID generation and usage
    static func basicUsage() {
        print("=== Basic XID Usage ===")

        // Generate a new XID
        let id = XID()
        print("Generated XID: \(id)")
        print("  - String representation: \(id.string)")
        print("  - Data length: \(id.data.count) bytes")
        print("  - Timestamp: \(id.timestamp)")

        // Parse from string
        do {
            let parsed = try XID(string: id.string)
            print("  - Successfully parsed back: \(parsed == id)")
        } catch {
            print("  - Error parsing: \(error)")
        }

        print()
    }

    /// Demonstrate sortability by generation time
    static func sortingExample() async {
        print("=== Sorting Example ===")

        var xids: [XID] = []

        // Generate XIDs with small delays
        for i in 0..<5 {
            xids.append(XID())
            print("Generated XID \(i + 1): \(xids.last!)")
            try? await Task.sleep(for: .milliseconds(1))
        }

        print("\nBefore sorting:")
        for (index, xid) in xids.enumerated() {
            print("  \(index): \(xid)")
        }

        // Sort XIDs - they should already be in order
        let sortedXIDs = xids.sorted()
        print("\nAfter sorting:")
        for (index, xid) in sortedXIDs.enumerated() {
            print("  \(index): \(xid)")
        }

        print("XIDs were already sorted: \(xids == sortedXIDs)")
        print()
    }

    /// Demonstrate XID components
    static func componentsExample() {
        print("=== XID Components ===")

        let xid = XID()
        print("XID: \(xid)")
        print("Components:")
        print("  - Timestamp: \(xid.timestamp)")
        print("  - Machine ID: \(xid.machineID.map { String(format: "%02x", $0) }.joined())")
        print("  - Process ID: \(xid.processID)")
        print("  - Counter: \(xid.counter)")

        // Create XID with specific timestamp
        let specificDate = Date(timeIntervalSince1970: 1_640_995_200)  // Jan 1, 2022
        let historicalXID = XID(timestamp: specificDate)
        print("\nHistorical XID (Jan 1, 2022): \(historicalXID)")
        print("  - Timestamp: \(historicalXID.timestamp)")

        print()
    }

    /// Demonstrate JSON serialization
    static func jsonExample() {
        print("=== JSON Serialization ===")

        struct User: Codable {
            let id: XID
            let name: String
            let createdAt: Date
        }

        let user = User(
            id: XID(),
            name: "Alice Johnson",
            createdAt: Date()
        )

        do {
            // Encode to JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted

            let jsonData = try encoder.encode(user)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            print("Encoded JSON:")
            print(jsonString)

            // Decode from JSON
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let decodedUser = try decoder.decode(User.self, from: jsonData)
            print("Decoded user:")
            print("  - ID: \(decodedUser.id)")
            print("  - Name: \(decodedUser.name)")
            print("  - Created: \(decodedUser.createdAt)")

        } catch {
            print("JSON error: \(error)")
        }

        print()
    }

    /// Demonstrate error handling
    static func errorHandlingExample() {
        print("=== Error Handling ===")

        // Invalid string examples
        let invalidStrings = [
            "too-short",
            "way-too-long-string-that-exceeds-20-chars",
            "invalid!@#$%characters",
            "",
        ]

        for invalidString in invalidStrings {
            do {
                let xid = try XID(string: invalidString)
                print("Unexpectedly parsed: \(xid)")
            } catch XIDError.invalidString {
                print("✓ Correctly rejected invalid string: '\(invalidString)'")
            } catch {
                print("✗ Unexpected error for '\(invalidString)': \(error)")
            }
        }

        // Invalid data examples
        let invalidDataSets = [
            Data([1, 2, 3]),  // Too short
            Data(repeating: 0, count: 20),  // Too long
            Data(),  // Empty
        ]

        for invalidData in invalidDataSets {
            do {
                _ = try XID(data: invalidData)
                print("Unexpectedly created XID from \(invalidData.count) bytes")
            } catch XIDError.invalidLength {
                print("✓ Correctly rejected data with \(invalidData.count) bytes")
            } catch {
                print("✗ Unexpected error for \(invalidData.count) bytes: \(error)")
            }
        }

        print()
    }

    /// Demonstrate concurrent generation
    static func concurrentExample() async {
        print("=== Concurrent Generation ===")

        let numberOfTasks = 5
        let xidsPerTask = 1000

        let startTime = ContinuousClock.now

        let allXIDs = await withTaskGroup(of: [XID].self, returning: [XID].self) { group in
            for taskIndex in 0..<numberOfTasks {
                group.addTask {
                    let xids = (0..<xidsPerTask).map { _ in XID() }
                    print("Task \(taskIndex + 1) generated \(xidsPerTask) XIDs")
                    return xids
                }
            }

            var result: [XID] = []
            for await xids in group {
                result.append(contentsOf: xids)
            }
            return result
        }

        let endTime = ContinuousClock.now

        let uniqueXIDs = Set(allXIDs)
        let totalGenerated = numberOfTasks * xidsPerTask

        print("Results:")
        print("  - Total XIDs generated: \(totalGenerated)")
        print("  - Unique XIDs: \(uniqueXIDs.count)")
        print("  - Duplicates: \(totalGenerated - uniqueXIDs.count)")
        let duration = endTime - startTime
        print("  - Time taken: \(String(format: "%.3f", duration.components.seconds)) seconds")
        print(
            "  - Rate: \(String(format: "%.0f", Double(totalGenerated) / Double(duration.components.seconds))) XIDs/second"
        )

        print()
    }

    /// Demonstrate performance characteristics
    static func performanceExample() {
        print("=== Performance Example ===")

        let iterations = 10_000

        // Generation performance
        let generationStart = ContinuousClock.now
        let xids = (0..<iterations).map { _ in XID() }
        let generationEnd = ContinuousClock.now

        print("Generation Performance:")
        let generationDuration = generationEnd - generationStart
        print(
            "  - Generated \(iterations) XIDs in \(String(format: "%.3f", generationDuration.components.seconds)) seconds"
        )
        print(
            "  - Rate: \(String(format: "%.0f", Double(iterations) / Double(generationDuration.components.seconds))) XIDs/second"
        )

        // String encoding performance
        let encodingStart = ContinuousClock.now
        let strings = xids.map { $0.string }
        let encodingEnd = ContinuousClock.now

        print("String Encoding Performance:")
        let encodingDuration = encodingEnd - encodingStart
        print(
            "  - Encoded \(iterations) XIDs in \(String(format: "%.3f", encodingDuration.components.seconds)) seconds"
        )
        print(
            "  - Rate: \(String(format: "%.0f", Double(iterations) / Double(encodingDuration.components.seconds))) encodings/second"
        )

        // String decoding performance
        let decodingStart = ContinuousClock.now
        let decodedXIDs = strings.compactMap { try? XID(string: $0) }
        let decodingEnd = ContinuousClock.now

        print("String Decoding Performance:")
        let decodingDuration = decodingEnd - decodingStart
        print(
            "  - Decoded \(decodedXIDs.count) XIDs in \(String(format: "%.3f", decodingDuration.components.seconds)) seconds"
        )
        print(
            "  - Rate: \(String(format: "%.0f", Double(decodedXIDs.count) / Double(decodingDuration.components.seconds))) decodings/second"
        )

        print()
    }

    /// Demonstrate using XIDs as database keys
    static func databaseKeyExample() async {
        print("=== Database Key Example ===")

        struct DatabaseRecord {
            let id: XID
            let data: String
            let createdAt: Date

            init(data: String) {
                self.id = XID()
                self.data = data
                self.createdAt = self.id.timestamp
            }
        }

        // Simulate creating database records
        var records: [DatabaseRecord] = []

        for i in 1...5 {
            let record = DatabaseRecord(data: "Record \(i)")
            records.append(record)
            try? await Task.sleep(for: .milliseconds(1))  // Small delay between records
        }

        print("Database Records:")
        for record in records {
            print("  ID: \(record.id.string)")
            print("  Data: \(record.data)")
            print("  Created: \(record.createdAt)")
            print("  ---")
        }

        // Records are naturally sorted by creation time due to XID sorting
        let sortedRecords = records.sorted { $0.id < $1.id }
        print(
            "Records are naturally chronologically ordered: \(records.map(\.id) == sortedRecords.map(\.id))"
        )

        print()
    }

    /// Run all examples
    static func runAll() async {
        print("🔹 Swift XID Examples 🔹\n")

        basicUsage()
        await sortingExample()
        componentsExample()
        jsonExample()
        errorHandlingExample()
        await concurrentExample()
        performanceExample()
        await databaseKeyExample()

        print("✅ All examples completed!")
    }
}

// Main entry point for executable
@main
struct ExamplesMain {
    static func main() async {
        await Examples.runAll()
    }
}
