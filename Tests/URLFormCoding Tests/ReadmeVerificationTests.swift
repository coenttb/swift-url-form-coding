import Testing
@testable import URLFormCoding

@Suite("README Verification")
struct ReadmeVerificationTests {

    @Test("Example from README: Basic Encoding/Decoding")
    func basicEncodingDecoding() throws {
        struct User: Codable {
            let name: String
            let email: String
            let age: Int
        }

        // Encoding
        let encoder = Form.Encoder()
        let user = User(name: "John Doe", email: "john@example.com", age: 30)
        let formData = try encoder.encode(user)

        // Verify encoding produces valid data
        #expect(formData.count > 0)

        // Decoding
        let decoder = Form.Decoder()
        let decodedUser = try decoder.decode(User.self, from: formData)

        // Verify round-trip
        #expect(decodedUser.name == user.name)
        #expect(decodedUser.email == user.email)
        #expect(decodedUser.age == user.age)
    }

    @Test("Example from README: Array Encoding Strategies")
    func arrayEncodingStrategies() throws {
        struct SearchQuery: Codable {
            let tags: [String]
        }

        let query = SearchQuery(tags: ["swift", "ios", "server"])

        // Accumulate Values (default)
        let encoder1 = Form.Encoder()
        encoder1.arrayEncodingStrategy = .accumulateValues
        let data1 = try encoder1.encode(query)
        #expect(data1.count > 0)

        // Brackets (PHP/Rails style)
        let encoder2 = Form.Encoder()
        encoder2.arrayEncodingStrategy = .brackets
        let data2 = try encoder2.encode(query)
        #expect(data2.count > 0)

        // Indexed Brackets
        let encoder3 = Form.Encoder()
        encoder3.arrayEncodingStrategy = .bracketsWithIndices
        let data3 = try encoder3.encode(query)
        #expect(data3.count > 0)
    }
}
