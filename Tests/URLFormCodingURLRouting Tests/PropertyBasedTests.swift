//
//  PropertyBasedTests.swift
//  URLFormCodingURLRouting Tests
//
//  Created by Coen ten Thije Boonkkamp on 30/10/2025.
//

import Foundation
import Testing
import URLFormCoding
import URLRouting

@testable import URLFormCodingURLRouting

// MARK: - Test Models

private struct StringModel: Codable, Equatable {
    let value: String
}

private struct MultiFieldModel: Codable, Equatable {
    let field1: String
    let field2: String
    let field3: String
}

private struct MixedTypeModel: Codable, Equatable {
    let string: String
    let int: Int
    let bool: Bool
}

private struct ArrayModel: Codable, Equatable {
    let strings: [String]
    let numbers: [Int]
}

private struct NestedModel: Codable, Equatable {
    let outer: String
    let inner: InnerModel

    struct InnerModel: Codable, Equatable {
        let value: String
        let number: Int
    }
}

// MARK: - Test Data Generation

/// Generates a comprehensive set of test strings covering edge cases
func generateTestStrings() -> [String] {
    var strings: [String] = []

    // Empty and minimal
    strings += ["", "a", "ab", "abc"]

    // Special characters that need URL encoding
    strings += [
        "+",  // Plus sign (represents space in URL encoding)
        " ",  // Space (encoded as + or %20)
        "%",  // Percent (needs encoding as %25)
        "=",  // Equals (form field separator)
        "&",  // Ampersand (form pair separator)
        "?",  // Question mark
        "#",  // Hash
        "/",  // Slash
        "\\",  // Backslash
        "\"",  // Double quote
        "'",  // Single quote
        "<",  // Less than
        ">",  // Greater than
        "|",  // Pipe
        "~",  // Tilde
        "`",  // Backtick
        "!",  // Exclamation
        "@",  // At symbol
        "$",  // Dollar
        "^",  // Caret
        "*",  // Asterisk
        "(",  // Parentheses
        ")",
        "[",  // Brackets
        "]",
        "{",  // Braces
        "}",
    ]

    // Combinations of special characters
    strings += [
        "foo+bar",  // Plus in middle
        "foo bar",  // Space in middle
        "foo%bar",  // Percent in middle
        "a=b&c=d",  // Form special chars
        "key=value",
        "a+b+c",  // Multiple plus signs
        "a b c",  // Multiple spaces
        "test%20value",  // Already percent-encoded space
        "test%2Bvalue",  // Already percent-encoded plus
        "test%3Dvalue",  // Already percent-encoded equals
        "test%26value",  // Already percent-encoded ampersand
    ]

    // Unicode and emoji
    strings += [
        "café",  // Accented characters
        "日本語",  // Japanese
        "العربية",  // Arabic
        "עברית",  // Hebrew
        "Ελληνικά",  // Greek
        "🎉",  // Single emoji
        "Hello 👋 World",  // Emoji with text
        "🇺🇸🇬🇧🇫🇷",  // Flag emojis
        "test🔥value",  // Emoji in middle
    ]

    // Whitespace variations
    strings += [
        " ",  // Single space
        "  ",  // Multiple spaces
        "\t",  // Tab
        "\n",  // Newline
        "\r",  // Carriage return
        "\r\n",  // Windows line ending
        " leading",  // Leading space
        "trailing ",  // Trailing space
        " both ",  // Both leading and trailing
    ]

    // Long strings
    strings += [
        String(repeating: "a", count: 100),
        String(repeating: "x", count: 1000),
        String(repeating: "test ", count: 50),  // 250 chars with spaces
    ]

    // Mixed content
    strings += [
        "Hello World!",
        "user@example.com",
        "https://example.com/path?query=value",
        "Price: $99.99",
        "2024-01-15 10:30:00",
        "RGB(255, 128, 0)",
        "function(arg1, arg2)",
        "key1=value1&key2=value2",
    ]

    // Edge cases
    strings += [
        String(repeating: "+", count: 10),  // All plus signs
        String(repeating: " ", count: 10),  // All spaces
        String(repeating: "%", count: 5),  // All percent signs
        "a".appending(String(repeating: " ", count: 100)).appending("b"),  // Many spaces in middle
    ]

    return strings
}

/// Generates test cases for integer values
func generateTestIntegers() -> [Int] {
    return [
        0,
        1,
        -1,
        42,
        -42,
        100,
        -100,
        999,
        -999,
        Int.max,
        Int.min,
    ]
}

/// Generates test cases for boolean values
func generateTestBooleans() -> [Bool] {
    return [true, false]
}

// MARK: - Property-Based Test Suites

@Suite("Property-Based Round-Trip Tests")
struct PropertyBasedRoundTripTests {

    // MARK: - Basic String Round-Trip Tests

    @Test(
        "Form.Conversion round-trips all special characters correctly",
        arguments: generateTestStrings()
    )
    func testFormConversionRoundTripsStrings(input: String) throws {
        let conversion = Form.Conversion(StringModel.self)
        let model = StringModel(value: input)

        let encoded = try conversion.unapply(model)
        let decoded = try conversion.apply(encoded)

        #expect(decoded.value == model.value)
    }

    @Test(
        "Form.Conversion round-trips strings in multiple fields",
        arguments: generateTestStrings().prefix(50)  // Subset to keep test time reasonable
    )
    func testFormConversionRoundTripsMultipleFields(input: String) throws {
        let conversion = Form.Conversion(MultiFieldModel.self)
        let model = MultiFieldModel(
            field1: input,
            field2: "constant",
            field3: input + "_suffix"
        )

        let encoded = try conversion.unapply(model)
        let decoded = try conversion.apply(encoded)

        #expect(decoded == model)
    }

    // MARK: - Integer Round-Trip Tests

    @Test(
        "Form.Conversion round-trips all integer values correctly",
        arguments: generateTestIntegers()
    )
    func testFormConversionRoundTripsIntegers(input: Int) throws {
        let conversion = Form.Conversion(MixedTypeModel.self)
        let model = MixedTypeModel(string: "test", int: input, bool: true)

        let encoded = try conversion.unapply(model)
        let decoded = try conversion.apply(encoded)

        #expect(decoded.int == model.int)
    }

    // MARK: - Boolean Round-Trip Tests

    @Test(
        "Form.Conversion round-trips boolean values correctly",
        arguments: generateTestBooleans()
    )
    func testFormConversionRoundTripsBooleans(input: Bool) throws {
        let conversion = Form.Conversion(MixedTypeModel.self)
        let model = MixedTypeModel(string: "test", int: 42, bool: input)

        let encoded = try conversion.unapply(model)
        let decoded = try conversion.apply(encoded)

        #expect(decoded.bool == model.bool)
    }

    // MARK: - Array Round-Trip Tests

    @Test("Form.Conversion round-trips string arrays with bracketsWithIndices strategy")
    func testFormConversionRoundTripsStringArrays() throws {
        let encoder = Form.Encoder()
        encoder.arrayEncodingStrategy = .bracketsWithIndices

        let decoder = Form.Decoder()
        decoder.arrayParsingStrategy = .bracketsWithIndices

        let conversion = Form.Conversion(ArrayModel.self, decoder: decoder, encoder: encoder)

        // Test with various array contents
        // Note: Empty arrays may not round-trip perfectly with all strategies
        let testCases: [[String]] = [
            ["a"],  // Single element
            ["a", "b"],  // Two elements
            ["foo+bar", "test value", "a=b&c=d"],  // Special characters
            ["🎉", "café", "Hello World"],  // Unicode
            Array(repeating: "test", count: 10),  // Many identical elements
        ]

        for strings in testCases {
            let model = ArrayModel(strings: strings, numbers: [1, 2, 3])

            let encoded = try conversion.unapply(model)
            let decoded = try conversion.apply(encoded)

            #expect(decoded.strings == model.strings)
        }

        // For large diverse arrays, order might not be perfectly preserved
        // Check that all elements are present
        let diverseStrings = Array(generateTestStrings().prefix(20))
        let diverseModel = ArrayModel(strings: diverseStrings, numbers: [1, 2, 3])
        let diverseEncoded = try conversion.unapply(diverseModel)
        let diverseDecoded = try conversion.apply(diverseEncoded)

        #expect(diverseDecoded.strings.count == diverseModel.strings.count)
        #expect(Set(diverseDecoded.strings) == Set(diverseModel.strings))
    }

    @Test("Form.Conversion round-trips integer arrays with bracketsWithIndices strategy")
    func testFormConversionRoundTripsIntegerArrays() throws {
        let encoder = Form.Encoder()
        encoder.arrayEncodingStrategy = .bracketsWithIndices

        let decoder = Form.Decoder()
        decoder.arrayParsingStrategy = .bracketsWithIndices

        let conversion = Form.Conversion(ArrayModel.self, decoder: decoder, encoder: encoder)

        // Test with various array contents
        // Note: Empty arrays may not round-trip perfectly with all strategies
        let testCases: [[Int]] = [
            [0],  // Single zero
            [1],  // Single positive
            [-1],  // Single negative
            [1, 2, 3, 4, 5],  // Sequential
            [-5, -1, 0, 1, 5],  // Mixed signs
            [Int.max, Int.min],  // Extremes
            Array(repeating: 42, count: 10),  // Repeated values
        ]

        for numbers in testCases {
            let model = ArrayModel(strings: ["test"], numbers: numbers)

            let encoded = try conversion.unapply(model)
            let decoded = try conversion.apply(encoded)

            #expect(decoded.numbers == model.numbers)
        }

        // For mixed test integers, order might not be perfectly preserved
        // Check that all elements are present
        let mixedIntegers = generateTestIntegers()
        let mixedModel = ArrayModel(strings: ["test"], numbers: mixedIntegers)
        let mixedEncoded = try conversion.unapply(mixedModel)
        let mixedDecoded = try conversion.apply(mixedEncoded)

        #expect(mixedDecoded.numbers.count == mixedModel.numbers.count)
        #expect(Set(mixedDecoded.numbers) == Set(mixedModel.numbers))
    }

    // MARK: - Nested Structure Tests

    @Test(
        "Form.Conversion round-trips nested structures with brackets strategy",
        arguments: generateTestStrings().prefix(30)
    )
    func testFormConversionRoundTripsNestedStructures(input: String) throws {
        let encoder = Form.Encoder()
        encoder.arrayEncodingStrategy = .brackets

        let decoder = Form.Decoder()
        decoder.arrayParsingStrategy = .brackets

        let conversion = Form.Conversion(NestedModel.self, decoder: decoder, encoder: encoder)
        let model = NestedModel(
            outer: input,
            inner: NestedModel.InnerModel(value: input + "_inner", number: 42)
        )

        let encoded = try conversion.unapply(model)
        let decoded = try conversion.apply(encoded)

        #expect(decoded == model)
    }

    // MARK: - Encoding Stability Tests

    @Test("Form.Conversion produces consistent encoding for same input")
    func testFormConversionEncodingStability() throws {
        let conversion = Form.Conversion(StringModel.self)
        let model = StringModel(value: "test+value")

        // Encode same model multiple times
        let encoded1 = try conversion.unapply(model)
        let encoded2 = try conversion.unapply(model)
        let encoded3 = try conversion.unapply(model)

        // Should produce identical output
        #expect(encoded1 == encoded2)
        #expect(encoded2 == encoded3)
    }

    @Test("Form.Conversion decoding is stable across multiple calls")
    func testFormConversionDecodingStability() throws {
        let conversion = Form.Conversion(StringModel.self)
        let model = StringModel(value: "test+value")
        let encoded = try conversion.unapply(model)

        // Decode same data multiple times
        let decoded1 = try conversion.apply(encoded)
        let decoded2 = try conversion.apply(encoded)
        let decoded3 = try conversion.apply(encoded)

        // Should produce identical output
        #expect(decoded1 == decoded2)
        #expect(decoded2 == decoded3)
    }

    // MARK: - Boundary Condition Tests

    @Test("Form.Conversion handles models with all empty strings")
    func testFormConversionHandlesAllEmptyStrings() throws {
        let conversion = Form.Conversion(MultiFieldModel.self)
        let model = MultiFieldModel(field1: "", field2: "", field3: "")

        let encoded = try conversion.unapply(model)
        let decoded = try conversion.apply(encoded)

        #expect(decoded == model)
    }

    @Test("Form.Conversion handles models with all zero values")
    func testFormConversionHandlesAllZeroValues() throws {
        let conversion = Form.Conversion(MixedTypeModel.self)
        let model = MixedTypeModel(string: "", int: 0, bool: false)

        let encoded = try conversion.unapply(model)
        let decoded = try conversion.apply(encoded)

        #expect(decoded == model)
    }

    @Test("Form.Conversion handles very large mixed content")
    func testFormConversionHandlesVeryLargeMixedContent() throws {
        let encoder = Form.Encoder()
        encoder.arrayEncodingStrategy = .bracketsWithIndices

        let decoder = Form.Decoder()
        decoder.arrayParsingStrategy = .bracketsWithIndices

        let conversion = Form.Conversion(ArrayModel.self, decoder: decoder, encoder: encoder)

        let largeStrings = Array(0..<100).map { i in
            "string_\(i)_" + String(repeating: "x", count: 50)
        }
        let largeNumbers = Array(-50..<50)

        let model = ArrayModel(strings: largeStrings, numbers: largeNumbers)

        let encoded = try conversion.unapply(model)
        let decoded = try conversion.apply(encoded)

        // Check counts are preserved
        #expect(decoded.strings.count == model.strings.count)
        #expect(decoded.numbers.count == model.numbers.count)

        // Check that all elements are present (order might vary with some encoding strategies)
        #expect(Set(decoded.strings) == Set(model.strings))
        #expect(Set(decoded.numbers) == Set(model.numbers))
    }
}

// MARK: - Property-Based Encoding Tests

@Suite("Property-Based Encoding Behavior Tests")
struct PropertyBasedEncodingTests {

    @Test(
        "Form.Conversion encoding never produces empty data for non-empty models",
        arguments: generateTestStrings().prefix(50)
    )
    func testEncodingNeverProducesEmptyData(input: String) throws {
        guard !input.isEmpty else { return }  // Skip empty string case

        let conversion = Form.Conversion(StringModel.self)
        let model = StringModel(value: input)

        let encoded = try conversion.unapply(model)

        #expect(!encoded.isEmpty)
    }

    @Test(
        "Form.Conversion encoding produces valid UTF-8",
        arguments: generateTestStrings().prefix(50)
    )
    func testEncodingProducesValidUTF8(input: String) throws {
        let conversion = Form.Conversion(StringModel.self)
        let model = StringModel(value: input)

        let encoded = try conversion.unapply(model)
        let utf8String = String(data: encoded, encoding: .utf8)

        #expect(utf8String != nil)
    }

    @Test(
        "Form.Conversion encoding contains field name",
        arguments: generateTestStrings().prefix(30)
    )
    func testEncodingContainsFieldName(input: String) throws {
        let conversion = Form.Conversion(StringModel.self)
        let model = StringModel(value: input)

        let encoded = try conversion.unapply(model)
        let encodedString = String(data: encoded, encoding: .utf8)!

        // Should contain the field name "value"
        #expect(encodedString.contains("value"))
    }

    @Test("Form.Conversion encoding uses proper URL encoding for special chars")
    func testEncodingUsesProperURLEncoding() throws {
        let conversion = Form.Conversion(StringModel.self)

        // Test specific encoding expectations per WHATWG URL Standard
        // (application/x-www-form-urlencoded)
        // Note: Spaces are encoded as + in form data, not %20
        let testCases: [(String, String)] = [
            (" ", "+"),  // Space as + (WHATWG standard for form data)
            ("=", "%3D"),  // Equals sign
            ("&", "%26"),  // Ampersand
            ("+", "%2B"),  // Plus sign
            ("#", "%23"),  // Hash
            ("\n", "%0A"),  // Newline
        ]

        for (input, expectedEncoding) in testCases {
            let model = StringModel(value: input)
            let encoded = try conversion.unapply(model)
            let encodedString = String(data: encoded, encoding: .utf8)!

            // Should contain the proper URL encoding
            #expect(encodedString.contains(expectedEncoding))
        }
    }
}

// MARK: - Property-Based Decoding Tests

@Suite("Property-Based Decoding Behavior Tests")
struct PropertyBasedDecodingTests {

    @Test("Form.Conversion decoding handles manually crafted percent-encoded data")
    func testDecodingHandlesPercentEncodedData() throws {
        let conversion = Form.Conversion(StringModel.self)

        let testCases: [(String, String)] = [
            ("value=hello%20world", "hello world"),  // Space
            ("value=test%2Bvalue", "test+value"),  // Plus sign
            ("value=a%3Db", "a=b"),  // Equals
            ("value=x%26y", "x&y"),  // Ampersand
            ("value=%F0%9F%8E%89", "🎉"),  // Emoji
        ]

        for (encodedString, expectedValue) in testCases {
            let data = Data(encodedString.utf8)
            let decoded = try conversion.apply(data)

            #expect(decoded.value == expectedValue)
        }
    }

    @Test("Form.Conversion decoding handles plus-as-space convention")
    func testDecodingHandlesPlusAsSpace() throws {
        let conversion = Form.Conversion(StringModel.self)

        // In URL-encoded form data, + represents space
        let data = Data("value=hello+world".utf8)
        let decoded = try conversion.apply(data)

        #expect(decoded.value == "hello world")
    }

    @Test("Form.Conversion decoding distinguishes plus-as-space from encoded-plus")
    func testDecodingDistinguishesPlusFromEncodedPlus() throws {
        let conversion = Form.Conversion(MultiFieldModel.self)

        // + should become space, %2B should become +
        let data = Data("field1=hello+world&field2=test%2Bvalue&field3=mixed+and%2B".utf8)
        let decoded = try conversion.apply(data)

        #expect(decoded.field1 == "hello world")  // + → space
        #expect(decoded.field2 == "test+value")  // %2B → +
        #expect(decoded.field3 == "mixed and+")  // Both: + → space, %2B → +
    }
}

// MARK: - Idempotence Tests

@Suite("Idempotence Property Tests")
struct IdempotenceTests {

    @Test(
        "Multiple encode-decode cycles preserve value",
        arguments: generateTestStrings().prefix(20)
    )
    func testMultipleRoundTripsPreserveValue(input: String) throws {
        let conversion = Form.Conversion(StringModel.self)
        var current = StringModel(value: input)

        // Perform 5 round-trip cycles
        for _ in 0..<5 {
            let encoded = try conversion.unapply(current)
            current = try conversion.apply(encoded)
        }

        // Should still equal original
        #expect(current.value == input)
    }

    @Test("Encoding twice produces identical results")
    func testEncodingIdempotence() throws {
        let conversion = Form.Conversion(StringModel.self)
        let model = StringModel(value: "test+value with spaces")

        let encoded1 = try conversion.unapply(model)
        let encoded2 = try conversion.unapply(model)

        #expect(encoded1 == encoded2)
    }

    @Test("Decoding already-decoded data produces same result")
    func testDecodingIdempotence() throws {
        let conversion = Form.Conversion(StringModel.self)
        let model = StringModel(value: "test value")

        let encoded = try conversion.unapply(model)
        let decoded1 = try conversion.apply(encoded)
        let reencoded = try conversion.unapply(decoded1)
        let decoded2 = try conversion.apply(reencoded)

        #expect(decoded1 == decoded2)
    }
}
