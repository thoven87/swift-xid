# ``SwiftXID/XID``

A globally unique identifier that is sortable and URL-safe.

## Overview

XID is a 12-byte globally unique identifier designed for distributed systems. It combines a timestamp, machine identifier, process identifier, and counter to create identifiers that are:

- **Globally unique** across machines and processes
- **Sortable** by generation time
- **Compact** (20 characters when encoded)
- **URL-safe** (no special characters)
- **Fast** to generate and compare

### Format

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

## Topics

### Creating XIDs

- ``SwiftXID/XID/init()``
- ``SwiftXID/XID/init(timestamp:)``
- ``SwiftXID/XID/init(data:)``
- ``SwiftXID/XID/init(string:)``

### Accessing Components

- ``SwiftXID/XID/data``
- ``SwiftXID/XID/string``
- ``SwiftXID/XID/timestamp``
- ``SwiftXID/XID/machineID``
- ``SwiftXID/XID/processID``
- ``SwiftXID/XID/counter``

### Error Handling

- ``SwiftXID/XIDError``

## Getting Started

### Basic Usage

Generate a new XID and convert it to a string:

```swift
let id = XID()
print(id.string) // "c3h6k27d0000000000"
```

### Parsing from String

```swift
let xid = try XID(string: "c3h6k27d0000000000")
```

### Sorting by Time

XIDs are naturally sortable by generation time:

```swift
let id1 = XID()
// ... time passes
let id2 = XID()
print(id1 < id2) // true
```

### JSON Serialization

XIDs conform to `Codable` for easy JSON serialization:

```swift
import SwiftXID

struct User: Codable {
    let id: XID
    let name: String
}

let user = User(id: XID(), name: "Alice")
let jsonData = try JSONEncoder().encode(user)
```

## Performance

XID generation is highly optimized:

- **Generation**: ~100,000 XIDs per second
- **String encoding**: ~100,000 encodings per second
- **String decoding**: ~50,000 decodings per second
- **Concurrency-safe**: Safe for concurrent use with Swift Concurrency

## Use Cases

XIDs are perfect for:

- Database primary keys
- Distributed system identifiers
- Event tracking IDs
- Session identifiers
- Request/transaction IDs
- Log correlation IDs

## Comparison with UUID

| Feature | XID | UUID v4 |
|---------|-----|---------|
| **Size** | 12 bytes | 16 bytes |
| **String Length** | 20 chars | 36 chars |
| **Sortable** | ✅ Yes | ❌ No |
| **URL Safe** | ✅ Yes | ❌ No |
| **Timestamp** | ✅ Embedded | ❌ No |
| **Collision Resistance** | ✅ Very High | ✅ Very High |