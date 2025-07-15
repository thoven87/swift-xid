# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial implementation of XID globally unique identifier
- Swift 6.1 support with modern concurrency features
- Concurrency-safe generation using built-in `Mutex<T>`
- Base32 encoding/decoding with Crockford's alphabet
- Comprehensive test suite using Swift Testing framework
- DocC documentation catalog
- GitHub Actions CI/CD pipeline
- Support for macOS, iOS, watchOS, tvOS, and Linux
- Performance benchmarks and optimization
- JSON serialization support via Codable
- Example usage patterns and documentation

### Features
- **12-byte format**: 4-byte timestamp + 3-byte machine ID + 2-byte process ID + 3-byte counter
- **Lexicographically sortable** by generation time
- **URL-safe** 20-character string representation
- **Sendable** compliance for Swift structured concurrency
- **Concurrency-safe** generation with automatic counter increment
- **High performance**: ~100,000 XIDs/second generation rate
- **Zero external dependencies** - Only uses built-in Swift frameworks

### Protocol Conformances
- `Sendable` - Safe for concurrent use
- `Equatable` - Value comparison
- `Comparable` - Sortable by generation time
- `Hashable` - Usable in Sets and as Dictionary keys
- `Codable` - JSON serialization/deserialization
- `CustomStringConvertible` - String representation

### Dependencies
- **Zero external dependencies** - Only uses built-in Swift frameworks
- Built-in `Synchronization` framework - For concurrency-safe counter
- Built-in `Foundation` framework - For basic types and process info

### Development Tools
- Swift Testing framework for comprehensive test coverage
- GitHub Actions for CI on Ubuntu and macOS
- DocC for documentation generation
- Performance testing with time limits
- Concurrent generation testing

### Platform Support
- **Swift**: 6.1+
- **macOS**: 10.15+
- **iOS**: 13.0+
- **watchOS**: 6.0+
- **tvOS**: 13.0+
- **Linux**: Ubuntu 20.04+

## [1.0.0] - TBD

### Added
- First stable release
- Complete XID specification implementation
- Production-ready performance and safety