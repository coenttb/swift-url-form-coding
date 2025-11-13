//
//  URLRouting+Form Tests.swift
//  URLRouting+Form Tests
//
//  Created by Coen ten Thije Boonkkamp on 26/07/2025.
//

import Foundation
import URLFormCoding
import Testing
import URLFormCoding
import URLRouting

@testable import URLFormCodingURLRouting

// MARK: - Test Models

private struct BasicUser: Codable, Equatable {
    let name: String
    let age: Int
    let isActive: Bool
}

private struct NestedUser: Codable, Equatable {
    let name: String
    let profile: Profile

    struct Profile: Codable, Equatable {
        let bio: String
        let website: String?
    }
}

private struct UserWithArrays: Codable, Equatable {
    let name: String
    let tags: [String]
    let scores: [Int]
}

private struct UserWithOptionals: Codable, Equatable {
    let name: String
    let email: String?
    let age: Int?
    let isVerified: Bool?
}

private struct UserWithDates: Codable, Equatable {
    let name: String
    let createdAt: Date
    let lastLogin: Date?
}

private struct UserWithData: Codable, Equatable {
    let name: String
    let avatar: Data
    let thumbnail: Data?
}

// MARK: - Main Test Suite

@Suite("URLRouting+Form Tests")
struct URLRoutingFormTests {

    // MARK: - FormCoding Basic Tests

    @Suite("FormCoding Basic Functionality")
    struct FormCodingBasicTests {

        @Test("FormCoding initializes with default encoder/decoder")
        func testFormCodingInitializesWithDefaults() {
            let formCoding = Form.Conversion(BasicUser.self)

            // Should successfully create FormCoding with encoder/decoder
            // Just verify we can access the properties without crashing
            _ = formCoding.encoder
            _ = formCoding.decoder
        }

        @Test("FormCoding initializes with custom encoder/decoder")
        func testFormCodingInitializesWithCustomEncoderDecoder() {
            let encoder = Form.Encoder(dateEncodingStrategy: .secondsSince1970)

            let decoder = Form.Decoder(dateDecodingStrategy: .secondsSince1970)

            let formCoding = Form.Conversion(BasicUser.self, decoder: decoder, encoder: encoder)

            // Verify that the FormCoding was created with the custom encoder/decoder
            // We can't directly compare the strategies as they don't conform to Equatable
            // but we can verify the FormCoding instance was created successfully
            _ = formCoding.encoder
            _ = formCoding.decoder
        }

        @Test("FormCoding apply method decodes data correctly")
        func testFormCodingApplyMethodDecodesCorrectly() throws {
            let formCoding = Form.Conversion(BasicUser.self)
            let queryString = "name=John%20Doe&age=30&isActive=true"
            let data = Data(queryString.utf8)

            let user = try formCoding.apply(data)

            #expect(user.name == "John Doe")
            #expect(user.age == 30)
            #expect(user.isActive == true)
        }

        @Test("FormCoding unapply method encodes data correctly")
        func testFormCodingUnapplyMethodEncodesCorrectly() throws {
            let formCoding = Form.Conversion(BasicUser.self)
            let user = BasicUser(name: "Jane Doe", age: 25, isActive: false)

            let data = try formCoding.unapply(user)
            let queryString = String(data: data, encoding: .utf8)!

            // WHATWG URL Standard: spaces are encoded as + in form data
            #expect(queryString.contains("name=Jane+Doe"))
            #expect(queryString.contains("age=25"))
            #expect(queryString.contains("isActive=false"))
        }

        @Test("FormCoding round-trips data correctly")
        func testFormCodingRoundTripsCorrectly() throws {
            let formCoding = Form.Conversion(BasicUser.self)
            let original = BasicUser(name: "Test User", age: 42, isActive: true)

            let encoded = try formCoding.unapply(original)
            let decoded = try formCoding.apply(encoded)

            #expect(decoded == original)
        }
    }

    // MARK: - Conversion Extension Tests

    @Suite("Conversion Extension Methods")
    struct ConversionExtensionTests {

        @Test("Conversion.form static method creates FormCoding")
        func testConversionFormStaticMethod() {
            let formCoding: Form.Conversion<BasicUser> = .form(BasicUser.self)

            // Should create a valid FormCoding instance
            _ = formCoding.encoder
            _ = formCoding.decoder
        }

        @Test("Conversion.form static method accepts custom encoder/decoder")
        func testConversionFormStaticMethodWithCustomSettings() {
            let encoder = Form.Encoder(dateEncodingStrategy: .millisecondsSince1970)

            let decoder = Form.Decoder(dateDecodingStrategy: .millisecondsSince1970)

            let formCoding: Form.Conversion<UserWithDates> = .form(
                UserWithDates.self,
                decoder: decoder,
                encoder: encoder
            )

            // Verify FormCoding was created successfully with custom settings
            _ = formCoding.encoder
            _ = formCoding.decoder
        }

        @Test("Conversion instance form method creates mapped conversion")
        func testConversionInstanceFormMethod() throws {
            // Create a simple conversion that transforms data
            struct IdentityConversion: URLRouting.Conversion {
                func apply(_ input: Data) throws -> Foundation.Data {
                    return input
                }

                func unapply(_ output: Data) throws -> Foundation.Data {
                    return output
                }
            }

            let identityConversion = IdentityConversion()
            let mappedConversion = identityConversion.form(BasicUser.self)

            // Test that the mapped conversion works
            let user = BasicUser(name: "Test", age: 30, isActive: true)
            let data = try mappedConversion.unapply(user)
            let decoded = try mappedConversion.apply(data)

            #expect(decoded == user)
        }
    }

    // MARK: - Complex Data Types Tests

    @Suite("Complex Data Types")
    struct ComplexDataTypesTests {

        @Test("FormCoding handles nested objects")
        func testFormCodingHandlesNestedObjects() throws {
            let decoder = Form.Decoder()
            decoder.arrayParsingStrategy = .brackets

            let formCoding = Form.Conversion(NestedUser.self, decoder: decoder)
            let queryString =
                "name=Alice&profile[bio]=Developer&profile[website]=https%3A//example.com"
            let data = Data(queryString.utf8)

            let user = try formCoding.apply(data)

            #expect(user.name == "Alice")
            #expect(user.profile.bio == "Developer")
            #expect(user.profile.website == "https://example.com")
        }

        @Test("FormCoding handles arrays with accumulate values strategy")
        func testFormCodingHandlesArrays() throws {
            let decoder = Form.Decoder()
            decoder.arrayParsingStrategy = .accumulateValues

            let formCoding = Form.Conversion(UserWithArrays.self, decoder: decoder)
            let queryString =
                "name=Charlie&tags=swift&tags=ios&tags=developer&scores=85&scores=92&scores=78"
            let data = Data(queryString.utf8)

            let user = try formCoding.apply(data)

            #expect(user.name == "Charlie")
            #expect(user.tags == ["swift", "ios", "developer"])
            #expect(user.scores == [85, 92, 78])
        }

        @Test("FormCoding handles optional values")
        func testFormCodingHandlesOptionalValues() throws {
            let formCoding = Form.Conversion(UserWithOptionals.self)

            // Test with some optionals present
            let queryString1 = "name=Frank&email=frank%40example.com&age=28"
            let data1 = Data(queryString1.utf8)
            let user1 = try formCoding.apply(data1)

            #expect(user1.name == "Frank")
            #expect(user1.email == "frank@example.com")
            #expect(user1.age == 28)
            #expect(user1.isVerified == nil)

            // Test with no optionals
            let queryString2 = "name=Grace"
            let data2 = Data(queryString2.utf8)
            let user2 = try formCoding.apply(data2)

            #expect(user2.name == "Grace")
            #expect(user2.email == nil)
            #expect(user2.age == nil)
            #expect(user2.isVerified == nil)
        }

        @Test("FormCoding handles dates with custom strategies")
        func testFormCodingHandlesDatesWithCustomStrategies() throws {
            let encoder = Form.Encoder(dateEncodingStrategy: .secondsSince1970)

            let decoder = Form.Decoder(dateDecodingStrategy: .secondsSince1970)

            let formCoding = Form.Conversion(UserWithDates.self, decoder: decoder, encoder: encoder)

            let date = Date(timeIntervalSince1970: 1_234_567_890)
            let original = UserWithDates(name: "DateUser", createdAt: date, lastLogin: date)

            let encoded = try formCoding.unapply(original)
            let decoded = try formCoding.apply(encoded)

            #expect(decoded == original)
        }

        @Test("FormCoding handles data with base64 strategy")
        func testFormCodingHandlesDataWithBase64Strategy() throws {
            let encoder = Form.Encoder(dataEncodingStrategy: .base64)

            let decoder = Form.Decoder(dataDecodingStrategy: .base64)

            let formCoding = Form.Conversion(UserWithData.self, decoder: decoder, encoder: encoder)

            let testData = "Hello World".data(using: .utf8)!
            let original = UserWithData(name: "DataUser", avatar: testData, thumbnail: testData)

            let encoded = try formCoding.unapply(original)
            let decoded = try formCoding.apply(encoded)

            #expect(decoded == original)
        }
    }

    // MARK: - Error Handling Tests

    @Suite("Error Handling")
    struct ErrorHandlingTests {

        @Test("FormCoding apply throws error for invalid data")
        func testFormCodingApplyThrowsErrorForInvalidData() {
            let formCoding = Form.Conversion(BasicUser.self)
            let invalidData = Data("invalid data".utf8)

            do {
                _ = try formCoding.apply(invalidData)
                #expect(Bool(false), "Expected decoding to throw an error")
            } catch {
                // Should throw a decoding error
                #expect(error is Form.Decoder.Error)
            }
        }

        @Test("FormCoding apply throws error for missing required fields")
        func testFormCodingApplyThrowsErrorForMissingFields() {
            let formCoding = Form.Conversion(BasicUser.self)
            let incompleteData = Data("name=Test".utf8)  // Missing age and isActive

            do {
                _ = try formCoding.apply(incompleteData)
                #expect(Bool(false), "Expected decoding to throw an error")
            } catch {
                #expect(error is Form.Decoder.Error)
            }
        }

        @Test("FormCoding apply throws error for invalid number format")
        func testFormCodingApplyThrowsErrorForInvalidNumberFormat() {
            let formCoding = Form.Conversion(BasicUser.self)
            let invalidData = Data("name=Test&age=not_a_number&isActive=true".utf8)

            do {
                _ = try formCoding.apply(invalidData)
                #expect(Bool(false), "Expected decoding to throw an error")
            } catch {
                #expect(error is Form.Decoder.Error)
            }
        }

        @Test("FormCoding unapply handles encoding errors gracefully")
        func testFormCodingUnapplyHandlesEncodingErrors() {
            // This test verifies that encoding generally succeeds for valid Codable types
            let formCoding = Form.Conversion(BasicUser.self)
            let user = BasicUser(name: "Test", age: 30, isActive: true)

            do {
                let data = try formCoding.unapply(user)
                #expect(!data.isEmpty)
            } catch {
                #expect(Bool(false), "Encoding should not fail for valid Codable types")
            }
        }
    }

    // MARK: - Round-trip Tests

    @Suite("Round-trip Compatibility")
    struct RoundTripTests {

        @Test("FormCoding round-trips basic types")
        func testFormCodingRoundTripsBasicTypes() throws {
            let formCoding = Form.Conversion(BasicUser.self)
            let original = BasicUser(name: "Round Trip User", age: 35, isActive: true)

            let encoded = try formCoding.unapply(original)
            let decoded = try formCoding.apply(encoded)

            #expect(decoded == original)
        }

        @Test("FormCoding round-trips arrays with compatible strategies")
        func testFormCodingRoundTripsArrays() throws {
            let encoder = Form.Encoder()
            encoder.arrayEncodingStrategy = .bracketsWithIndices

            let decoder = Form.Decoder()
            decoder.arrayParsingStrategy = .bracketsWithIndices  // Compatible with encoder output

            let formCoding = Form.Conversion(
                UserWithArrays.self,
                decoder: decoder,
                encoder: encoder
            )
            let original = UserWithArrays(
                name: "Array User",
                tags: ["swift", "ios", "macos"],
                scores: [95, 88, 92]
            )

            let encoded = try formCoding.unapply(original)
            let decoded = try formCoding.apply(encoded)

            #expect(decoded == original)
        }

        @Test("FormCoding round-trips optional values")
        func testFormCodingRoundTripsOptionalValues() throws {
            let formCoding = Form.Conversion(UserWithOptionals.self)

            // Test with mixed optional values
            let original = UserWithOptionals(
                name: "Optional User",
                email: "test@example.com",
                age: nil,
                isVerified: true
            )

            let encoded = try formCoding.unapply(original)
            let decoded = try formCoding.apply(encoded)

            #expect(decoded == original)
        }

        @Test("FormCoding round-trips with matching date strategies")
        func testFormCodingRoundTripsWithMatchingDateStrategies() throws {
            let encoder = Form.Encoder(dateEncodingStrategy: .iso8601)

            let decoder = Form.Decoder(dateDecodingStrategy: .iso8601)

            let formCoding = Form.Conversion(UserWithDates.self, decoder: decoder, encoder: encoder)

            let date = Date(timeIntervalSince1970: 1_234_567_890)
            let original = UserWithDates(
                name: "Date User",
                createdAt: date,
                lastLogin: date
            )

            let encoded = try formCoding.unapply(original)
            let decoded = try formCoding.apply(encoded)

            #expect(decoded.name == original.name)
            #expect(
                abs(
                    decoded.createdAt.timeIntervalSince1970
                        - original.createdAt.timeIntervalSince1970
                )
                    < 1.0
            )
            #expect(
                abs(
                    decoded.lastLogin!.timeIntervalSince1970
                        - original.lastLogin!.timeIntervalSince1970
                )
                    < 1.0
            )
        }
    }

    // MARK: - Edge Cases Tests

    @Suite("Edge Cases")
    struct EdgeCasesTests {

        @Test("FormCoding handles empty data")
        func testFormCodingHandlesEmptyData() {
            let formCoding = Form.Conversion(UserWithOptionals.self)
            let emptyData = Data()

            do {
                _ = try formCoding.apply(emptyData)
                #expect(Bool(false), "Expected decoding to throw an error for empty data")
            } catch {
                #expect(error is Form.Decoder.Error)
            }
        }

        @Test("FormCoding handles very long strings")
        func testFormCodingHandlesVeryLongStrings() throws {
            let formCoding = Form.Conversion(BasicUser.self)
            let longName = String(repeating: "a", count: 10000)
            let original = BasicUser(name: longName, age: 25, isActive: true)

            let encoded = try formCoding.unapply(original)
            let decoded = try formCoding.apply(encoded)

            #expect(decoded == original)
        }

        @Test("FormCoding handles Unicode characters")
        func testFormCodingHandlesUnicodeCharacters() throws {
            let formCoding = Form.Conversion(BasicUser.self)
            let original = BasicUser(name: "José María 🇪🇸", age: 30, isActive: true)

            let encoded = try formCoding.unapply(original)
            let decoded = try formCoding.apply(encoded)

            #expect(decoded == original)
        }

        @Test("FormCoding handles special characters")
        func testFormCodingHandlesSpecialCharacters() throws {
            let formCoding = Form.Conversion(BasicUser.self)
            let original = BasicUser(name: "test=value&other=data", age: 30, isActive: true)

            let encoded = try formCoding.unapply(original)
            let decoded = try formCoding.apply(encoded)

            #expect(decoded == original)
        }

        @Test("FormCoding handles large numbers")
        func testFormCodingHandlesLargeNumbers() throws {
            let formCoding = Form.Conversion(BasicUser.self)
            let original = BasicUser(name: "Test", age: Int.max, isActive: false)

            let encoded = try formCoding.unapply(original)
            let decoded = try formCoding.apply(encoded)

            #expect(decoded == original)
        }
    }

    // MARK: - Strategy Compatibility Tests

    @Suite("Strategy Compatibility")
    struct StrategyCompatibilityTests {

        @Test("FormCoding works with accumulateValues parsing strategy")
        func testFormCodingWorksWithAccumulateValuesStrategy() throws {
            let decoder = Form.Decoder()
            decoder.arrayParsingStrategy = .accumulateValues

            let formCoding = Form.Conversion(UserWithArrays.self, decoder: decoder)

            // Test with manually crafted query string that matches accumulateValues format
            let queryString = "name=Strategy%20Test&tags=swift&tags=ios&scores=95&scores=88"
            let data = Data(queryString.utf8)

            let decoded = try formCoding.apply(data)

            #expect(decoded.name == "Strategy Test")
            #expect(decoded.tags == ["swift", "ios"])
            #expect(decoded.scores == [95, 88])
        }

        @Test("FormCoding works with brackets parsing strategy")
        func testFormCodingWorksWithBracketsStrategy() throws {
            let decoder = Form.Decoder()
            decoder.arrayParsingStrategy = .brackets

            let formCoding = Form.Conversion(NestedUser.self, decoder: decoder)
            let original = NestedUser(
                name: "Nested Test",
                profile: NestedUser.Profile(bio: "Developer", website: "https://example.com")
            )

            // Manual encoding to match brackets format
            let queryString =
                "name=Nested%20Test&profile[bio]=Developer&profile[website]=https%3A//example.com"
            let data = Data(queryString.utf8)

            let decoded = try formCoding.apply(data)

            #expect(decoded.name == original.name)
            #expect(decoded.profile.bio == original.profile.bio)
            #expect(decoded.profile.website == original.profile.website)
        }

        @Test("FormCoding works with bracketsWithIndices parsing strategy")
        func testFormCodingWorksWithBracketsWithIndicesStrategy() throws {
            let encoder = Form.Encoder()
            encoder.arrayEncodingStrategy = .bracketsWithIndices

            let decoder = Form.Decoder()
            decoder.arrayParsingStrategy = .bracketsWithIndices

            let formCoding = Form.Conversion(
                UserWithArrays.self,
                decoder: decoder,
                encoder: encoder
            )
            let original = UserWithArrays(
                name: "Indices Test",
                tags: ["swift", "vapor"],
                scores: [95, 88]
            )

            let encoded = try formCoding.unapply(original)
            let decoded = try formCoding.apply(encoded)

            #expect(decoded == original)
        }

        @Test("FormCoding works with custom parsing strategy")
        func testFormCodingWorksWithCustomParsingStrategy() throws {
            let decoder = Form.Decoder()
            decoder.arrayParsingStrategy = .custom { query in
                // Simple custom strategy - convert to key-value pairs
                var params: [String: Form.Decoder.Container] = [:]
                let pairs = query.split(separator: "&")

                for pair in pairs {
                    let components = pair.split(separator: "=", maxSplits: 1)
                    if components.count == 2 {
                        let key = String(components[0])
                        let value =
                            String(components[1]).removingPercentEncoding ?? String(components[1])
                        // Create container explicitly to avoid potential memory issues
                        let container = Form.Decoder.Container.singleValue(value)
                        params[key] = container
                    }
                }

                return .keyed(params)
            }

            let formCoding = Form.Conversion(BasicUser.self, decoder: decoder)
            let queryString = "name=Custom%20Test&age=42&isActive=true"
            let data = Data(queryString.utf8)

            let decoded = try formCoding.apply(data)

            #expect(decoded.name == "Custom Test")
            #expect(decoded.age == 42)
            #expect(decoded.isActive == true)
        }
    }

    // MARK: - Performance Tests

    @Suite("Performance")
    struct PerformanceTests {

        @Test("FormCoding handles large datasets efficiently")
        func testFormCodingHandlesLargeDatasetsEfficiently() throws {
            let encoder = Form.Encoder()
            encoder.arrayEncodingStrategy = .bracketsWithIndices

            let decoder = Form.Decoder()
            decoder.arrayParsingStrategy = .bracketsWithIndices  // Use compatible strategy

            let formCoding = Form.Conversion(
                UserWithArrays.self,
                decoder: decoder,
                encoder: encoder
            )

            let largeTags = Array(0..<1000).map { "tag\($0)" }
            let largeScores = Array(0..<1000)
            let original = UserWithArrays(
                name: "Performance Test",
                tags: largeTags,
                scores: largeScores
            )

            // Should complete without timeout
            let encoded = try formCoding.unapply(original)
            let decoded = try formCoding.apply(encoded)

            #expect(decoded.name == original.name)
            #expect(decoded.tags.count == 1000)
            #expect(decoded.scores.count == 1000)
        }
    }
}
