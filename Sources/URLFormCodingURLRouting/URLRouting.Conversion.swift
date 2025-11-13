import Foundation
import URLFormCoding
import URLRouting

extension URLRouting.Conversion {
    /// Creates a URL form data conversion for the specified Codable type.
    ///
    /// This static method provides a convenient way to create ``FormCoding``
    /// instances for use in URLRouting route definitions. Form coding handles
    /// standard web form data (application/x-www-form-urlencoded).
    ///
    /// - Parameters:
    ///   - type: The Codable type to convert to/from form data
    ///   - decoder: Optional custom URL form decoder (uses default if not provided)
    ///   - encoder: Optional custom URL form encoder (uses default if not provided)
    /// - Returns: A ``FormCoding`` conversion instance
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct LoginRequest: Codable {
    ///     let username: String
    ///     let password: String
    /// }
    ///
    /// // Create conversion with default encoder/decoder
    /// let loginConversion = Conversion.form(LoginRequest.self)
    ///
    /// // Create conversion with custom configuration
    /// let decoder = Form.Decoder()
    /// decoder.parsingStrategy = .brackets
    /// let encoder = Form.Encoder()
    /// encoder.dateEncodingStrategy = .iso8601
    ///
    /// let customConversion = Conversion.form(
    ///     LoginRequest.self,
    ///     decoder: decoder,
    ///     encoder: encoder
    /// )
    /// ```
    ///
    /// ## Usage in Routes
    ///
    /// ```swift
    /// Route {
    ///     Method.post
    ///     Path { "login" }
    ///     Body(.form(LoginRequest.self))
    /// }
    /// ```
    public static func form<Value>(
        _ type: Value.Type,
        decoder: Form.Decoder = .init(),
        encoder: Form.Encoder = .init()
    ) -> Self where Self == Form.Conversion<Value> {
        .init(type, decoder: decoder, encoder: encoder)
    }

    /// Maps this conversion through a URL form data conversion.
    ///
    /// This method allows you to chain conversions, applying form data
    /// conversion after another conversion has been applied.
    ///
    /// - Parameters:
    ///   - type: The Codable type to convert to/from form data
    ///   - decoder: Optional custom URL form decoder (uses default if not provided)
    ///   - encoder: Optional custom URL form encoder (uses default if not provided)
    /// - Returns: A mapped conversion that applies both conversions in sequence
    ///
    /// ## Example
    ///
    /// ```swift
    /// struct APIRequest: Codable {
    ///     let data: UserProfile
    /// }
    ///
    /// // Chain conversions: first transform data, then apply form conversion
    /// let chainedConversion = Conversion<Data, Data>.identity
    ///     .form(UserProfile.self)
    /// ```
    public func form<Value>(
        _ type: Value.Type,
        decoder: Form.Decoder = .init(),
        encoder: Form.Encoder = .init()
    ) -> Conversions.Map<Self, Form.Conversion<Value>> {
        self.map(.form(type, decoder: decoder, encoder: encoder))
    }
}
