# swift-xid

A Swift implementation of [XID](https://github.com/rs/xid) - a globally unique identifier that is sortable and URL-safe.

[![CI](https://github.com/thoven87/swift-xid/workflows/CI/badge.svg)](https://github.com/thoven87/swift-xid/actions)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fthoven87%2Fswift-xid%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/thoven87/swift-xid)
[![(https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fthoven87%2Fswift-xid%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/thoven87/swift-xid)](https://swift.org)
[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Swift Concurrency](https://img.shields.io/badge/Swift%20Concurrency-Ready-blue.svg)](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

## Overview

XID is a 12-byte globally unique identifier that combines:
- **4-byte timestamp** (seconds since Unix epoch)
- **3-byte machine identifier** (derived from hostname hash)
- **2-byte process identifier**
- **3-byte counter** (concurrency-safe, incrementing)

This results in identifiers that are:
- ✅ **Globally unique** across machines and processes
- ✅ **Sortable** by generation time (lexicographically)
- ✅ **Compact** (20 characters when base32-encoded)
- ✅ **URL-safe** (no special characters)
- ✅ **Concurrency-safe** with modern Swift Mutex
- ✅ **Sendable** for Swift structured concurrency
- ✅ **Fast** to generate and encode/decode

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/thoven87/swift-xid.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Package Dependencies
2. Enter: `https://github.com/thoven87/swift-xid.git`

## Running Examples

The project includes comprehensive examples demonstrating all XID features:

```bash
cd Examples
swift run
```

This will run through various usage patterns including:
- Basic XID generation and parsing
- Sorting by timestamp
- Component extraction
- JSON serialization
- Error handling
- Concurrent generation
- Performance benchmarks
- Database key usage patterns

## Quick Start

```swift
import SwiftXID

// Generate a new XID
let id = XID()
print(id.string) // "c3h6k27d0000000000"

// Parse from string
let parsed = try XID(string: "c3h6k27d0000000000")

// XIDs are sortable by generation time
let id1 = XID()
// ... some time passes
let id2 = XID()
print(id1 < id2) // true

// Access components
print("Timestamp: \(id.timestamp)")
print("Machine ID: \(id.machineID.map { String(format: "%02x", $0) }.joined())")
print("Process ID: \(id.processID)")
print("Counter: \(id.counter)")
```

## Usage Examples

### Basic Usage

```swift
import SwiftXID

// Generate new XIDs
let userID = XID()
let sessionID = XID()
let requestID = XID()

// Convert to string for storage/transmission
let userIDString = userID.string
// Store in database, send via API, etc.
```

### Working with Timestamps

```swift
// Create XID with specific timestamp
let specificTime = Date(timeIntervalSince1970: 1640995200) // Jan 1, 2022
let historicalID = XID(timestamp: specificTime)

// Extract timestamp from existing XID
let currentID = XID()
print("Generated at: \(currentID.timestamp)")
```

### Sorting and Ordering

```swift
// Async function to demonstrate sorting
func generateSortedEvents() async -> [XID] {
    var events: [XID] = []

    // Generate events over time
    for i in 0..<10 {
        events.append(XID())
        try? await Task.sleep(for: .milliseconds(1)) // Small delay
    }

    // XIDs naturally sort by creation time
    events.sort()
    // Events are now in chronological order
    return events
}

// Usage
let sortedEvents = await generateSortedEvents()
```

### JSON Serialization

```swift
import Foundation

// XID conforms to Codable
struct User: Codable {
    let id: XID
    let name: String
}

let user = User(id: XID(), name: "Alice")
let jsonData = try JSONEncoder().encode(user)
let decodedUser = try JSONDecoder().decode(User.self, from: jsonData)
```

### Error Handling

```swift
// Handle invalid XID strings
do {
    let xid = try XID(string: "invalid-xid-string")
} catch XIDError.invalidString {
    print("Invalid XID string format")
} catch XIDError.invalidLength {
    print("XID data must be exactly 12 bytes")
}

// Handle invalid data
do {
    let xid = try XID(data: Data([1, 2, 3])) // Too short
} catch XIDError.invalidLength {
    print("XID requires exactly 12 bytes")
}
```

### Concurrent Generation with Swift Concurrency

```swift
// XIDs are Sendable and concurrency-safe
let allIDs = await withTaskGroup(of: [XID].self, returning: [XID].self) { group in
    for _ in 0..<10 {
        group.addTask {
            return (0..<1000).map { _ in XID() }
        }
    }

    var result: [XID] = []
    for await ids in group {
        result.append(contentsOf: ids)
    }
    return result
}

// All 10,000 XIDs will be unique
let uniqueIDs = Set(allIDs)
assert(uniqueIDs.count == allIDs.count)
```

## API Reference

### Initializers

```swift
// Generate new XID with current timestamp
XID()

// Generate XID with specific timestamp
XID(timestamp: Date)

// Create from raw 12-byte data
XID(data: Data) throws

// Parse from base32 string
XID(string: String) throws
```

### Properties

```swift
// Raw 12-byte data
var data: Data { get }

// Base32-encoded string (20 characters)
var string: String { get }

// Timestamp component
var timestamp: Date { get }

// Machine identifier (3 bytes)
var machineID: Data { get }

// Process identifier
var processID: UInt16 { get }

// Counter value
var counter: UInt32 { get }
```

### Protocols

XID conforms to:
- `Sendable` - Safe to use across concurrency boundaries
- `Equatable` - Can be compared for equality
- `Comparable` - Sortable (by generation time)
- `Hashable` - Can be used in Sets and Dictionary keys
- `Codable` - JSON serializable
- `CustomStringConvertible` - String representation

### Error Types

```swift
enum XIDError: Error {
    case invalidLength  // Data is not exactly 12 bytes
    case invalidString  // String cannot be decoded as XID
}
```

## Performance

XID generation is highly optimized:

- **Generation**: ~100,000 XIDs per second
- **String encoding**: ~100,000 encodings per second
- **String decoding**: ~50,000 decodings per second
- **Memory usage**: 12 bytes per XID + minimal overhead

## Format Specification

XID follows the original specification:

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                      32-bit timestamp (seconds)                |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|          24-bit machine id            |    16-bit process id    |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                  24-bit counter                   |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

- **Timestamp**: Seconds since Unix epoch (big-endian)
- **Machine ID**: Hash of hostname (first 3 bytes)
- **Process ID**: Current process ID (2 bytes, big-endian)
- **Counter**: Incrementing counter (3 bytes, big-endian)

## Comparison with UUID

| Feature | XID | UUID v4 |
|---------|-----|---------|
| **Size** | 12 bytes | 16 bytes |
| **String Length** | 20 chars | 36 chars |
| **Sortable** | ✅ Yes | ❌ No |
| **URL Safe** | ✅ Yes | ❌ No (contains `-`) |
| **Timestamp** | ✅ Embedded | ❌ No |
| **Collision Resistance** | ✅ Very High | ✅ Very High |

## Requirements

- Swift 6.1+
- macOS 15.0+ / iOS 17.0+ / watchOS 10.0+ / tvOS 17.0+
- Built-in `Synchronization` framework (no external dependencies for concurrency)

**Note**: Higher platform requirements are needed for the modern `Mutex<T>` API from the built-in Synchronization framework.

## Dependencies

**Zero external dependencies!** 🎉

This package only uses built-in Swift frameworks:
- Built-in `Synchronization` framework - For concurrency-safe counter with Mutex
- Built-in `Foundation` framework - For basic types and process info

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Original XID specification by [Olivier Poitrey](https://github.com/rs/xid)
- Inspired by MongoDB ObjectID and Snowflake ID
- Built with modern Swift 6.1 concurrency features
