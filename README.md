# swift-url-form-coding

A Swift package for encoding and decoding `application/x-www-form-urlencoded` data with Codable support.

## Overview

`swift-url-form-coding` provides type-safe conversion between Swift's Codable types and URL-encoded form data, the standard format used by HTML forms and many web APIs.

## Features

- ✅ **Codable Integration**: Seamlessly encode/decode Swift types to/from form data
- ✅ **Multiple Encoding Strategies**: Support for PHP-style brackets, indexed arrays, and more
- ✅ **URLRouting Integration**: First-class support for PointFree's URLRouting
- ✅ **RFC Compliant**: Built on [RFC 2388](https://datatracker.ietf.org/doc/html/rfc2388) and [WHATWG URL Encoding](https://url.spec.whatwg.org/)
- ✅ **Swift 6.0**: Full strict concurrency support
- ✅ **Comprehensive Tests**: 218 tests covering edge cases and round-trip conversions

## Installation

Add this package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/coenttb/swift-url-form-coding", from: "0.1.0")
]
```

Then add the product to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "URLFormCoding", package: "swift-url-form-coding")
    ]
)
```

## Quick Start

### Basic Encoding/Decoding

```swift
import URLFormCoding

struct User: Codable {
    let name: String
    let email: String
    let age: Int
}

// Encoding
let encoder = Form.Encoder()
let user = User(name: "John Doe", email: "john@example.com", age: 30)
let formData = try encoder.encode(user)
// Result: "name=John%20Doe&email=john%40example.com&age=30"

// Decoding
let decoder = Form.Decoder()
let decodedUser = try decoder.decode(User.self, from: formData)
```

### Array Encoding Strategies

```swift
struct SearchQuery: Codable {
    let tags: [String]
}

let query = SearchQuery(tags: ["swift", "ios", "server"])

// Accumulate Values (default)
let encoder1 = Form.Encoder()
encoder1.arrayEncodingStrategy = .accumulateValues
// Result: "tags=swift&tags=ios&tags=server"

// Brackets (PHP/Rails style)
let encoder2 = Form.Encoder()
encoder2.arrayEncodingStrategy = .brackets
// Result: "tags[]=swift&tags[]=ios&tags[]=server"

// Indexed Brackets
let encoder3 = Form.Encoder()
encoder3.arrayEncodingStrategy = .bracketsWithIndices
// Result: "tags[0]=swift&tags[1]=ios&tags[2]=server"
```

### URLRouting Integration

```swift
import URLFormCodingURLRouting
import URLRouting

struct ContactForm: Codable {
    let name: String
    let email: String
    let message: String
}

let contactRoute = Route {
    Method.post
    Path { "contact" }
    Body(.form(ContactForm.self))
}
```

## Modules

- **URLFormCoding**: Core encoding/decoding functionality
- **URLFormCodingURLRouting**: Integration with PointFree's [swift-url-routing](https://github.com/pointfreeco/swift-url-routing)

## Dependencies

- [swift-rfc-2388](https://github.com/swift-standards/swift-rfc-2388) - Form data parsing/encoding strategies
- [swift-whatwg-url-encoding](https://github.com/swift-standards/swift-whatwg-url-encoding) - Percent encoding
- [swift-url-routing](https://github.com/pointfreeco/swift-url-routing) - URLRouting integration

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## Related Packages

- [swift-multipart-form-coding](https://github.com/coenttb/swift-multipart-form-coding) - Multipart form data encoding with file uploads
- [swift-form-coding](https://github.com/coenttb/swift-form-coding) - Umbrella package that re-exports both

## Credits

Originally based on PointFree's `UrlFormEncoding` from [swift-web](https://github.com/pointfreeco/swift-web), modernized with RFC compliance and URLRouting integration.
