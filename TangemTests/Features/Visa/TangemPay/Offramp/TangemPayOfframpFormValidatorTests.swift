//
//  TangemPayOfframpFormValidatorTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import Tangem

@Suite("TangemPay off-ramp form validation")
struct TangemPayOfframpFormValidatorTests {
    typealias Field = TangemPayFormField.ID

    private static let requiredFields: [Field] = [
        .email, .accountNumber, .routingNumber, .firstName, .lastName, .businessName, .countryCode,
        .region, .city, .line1, .postalCode, .bankName, .bankRegion, .bankCity, .bankLine1, .bankPostalCode,
    ]

    private static let validSamples: [(Field, String)] = [
        (.email, "john@example.com"),
        (.accountNumber, "000123456789"),
        (.routingNumber, "021000021"),
        (.firstName, "John"),
        (.lastName, "Doe"),
        (.businessName, "Acme Inc."),
        (.countryCode, "US"),
        (.region, "California"),
        (.city, "San Francisco"),
        (.line1, "1 Market Street"),
        (.line2, "Suite 100"),
        (.postalCode, "94105"),
        (.bankName, "Chase Bank"),
        (.bankRegion, "New York"),
        (.bankCity, "New York"),
        (.bankLine1, "383 Madison Avenue"),
        (.bankPostalCode, "10179"),
    ]

    private static let postalCodeFields: [Field] = [.postalCode, .bankPostalCode]
    private static let nameFields: [Field] = [.firstName, .lastName, .businessName, .bankName]
    private static let addressFields: [Field] = [.region, .bankRegion, .city, .line1, .line2, .bankCity, .bankLine1]

    // MARK: - Required and optional fields

    @Test("every field accepts a valid value", arguments: Self.validSamples)
    func filledFieldPasses(field: Field, text: String) {
        #expect(error(for: field, text, countryCode: "US") == nil)
    }

    @Test("an empty required field is reported as required", arguments: Self.requiredFields)
    func emptyRequiredFieldIsRequired(field: Field) {
        #expect(error(for: field, "") == .required)
    }

    @Test("whitespace-only input counts as empty", arguments: Self.requiredFields)
    func whitespaceOnlyInputIsRequired(field: Field) {
        #expect(error(for: field, " \t\n ") == .required)
    }

    @Test("the optional second address line may stay blank", arguments: ["", "   "])
    func optionalAddressLineMayStayBlank(text: String) {
        #expect(error(for: .line2, text) == nil)
    }

    // MARK: - Email

    @Test("a well-formed email passes", arguments: ["john@example.com", "john.doe+offramp@mail.example.co.uk"])
    func wellFormedEmailPasses(text: String) {
        #expect(error(for: .email, text) == nil)
    }

    @Test(
        "a malformed email is rejected",
        arguments: ["john", "john@", "@example.com", "john@example", "john doe@example.com", "john@@example.com"]
    )
    func malformedEmailIsRejected(text: String) {
        #expect(error(for: .email, text) == .invalidEmail)
    }

    @Test("a single-letter top-level domain is rejected")
    func singleLetterTopLevelDomainIsRejected() {
        #expect(error(for: .email, "john@example.c") == .invalidEmail)
    }

    @Test("an email is capped at 254 characters")
    func emailIsCappedAt254Characters() {
        #expect(error(for: .email, email(length: 254)) == nil)
        #expect(error(for: .email, email(length: 255)) == .invalidEmail)
    }

    @Test("whitespace around an email is ignored")
    func whitespaceAroundEmailIsIgnored() {
        #expect(error(for: .email, "  john@example.com\n") == nil)
    }

    // MARK: - Account number

    @Test("a numeric account number passes")
    func numericAccountNumberPasses() {
        #expect(error(for: .accountNumber, "000123456789") == nil)
    }

    @Test("an account number with non-digit characters is rejected", arguments: ["1234-5678", "12AB5678", "1234 5678"])
    func accountNumberWithNonDigitsIsRejected(text: String) {
        #expect(error(for: .accountNumber, text) == .invalidFormat)
    }

    @Test("the shortest and longest account numbers pass", arguments: ["1234", "12345678901234567"])
    func accountNumberAtLengthBoundsPasses(text: String) {
        #expect(error(for: .accountNumber, text) == nil)
    }

    @Test("an account number one digit too short or too long is rejected", arguments: ["123", "123456789012345678"])
    func accountNumberOutsideLengthBoundsIsRejected(text: String) {
        #expect(error(for: .accountNumber, text) == .invalidFormat)
    }

    @Test("an account number typed in non-ASCII digits is rejected")
    func accountNumberWithNonASCIIDigitsIsRejected() {
        #expect(error(for: .accountNumber, "١٢٣٤٥٦٧٨") == .invalidFormat)
    }

    // MARK: - Routing number

    @Test("a nine-digit routing number passes")
    func nineDigitRoutingNumberPasses() {
        #expect(error(for: .routingNumber, "021000021") == nil)
    }

    @Test("a routing number with non-digit characters is rejected", arguments: ["02100002A", "021-000-021"])
    func routingNumberWithNonDigitsIsRejected(text: String) {
        #expect(error(for: .routingNumber, text) == .routingNumber)
    }

    @Test("a routing number one digit too short or too long is rejected", arguments: ["02100002", "0210000210"])
    func routingNumberOfWrongLengthIsRejected(text: String) {
        #expect(error(for: .routingNumber, text) == .routingNumber)
    }

    @Test("whitespace around a routing number is ignored")
    func whitespaceAroundRoutingNumberIsIgnored() {
        #expect(error(for: .routingNumber, " 021000021\n") == nil)
    }

    // MARK: - US postal code

    @Test("a ZIP or ZIP+4 code passes", arguments: Self.postalCodeFields, ["94105", "94105-1234"])
    func usPostalCodePasses(field: Field, text: String) {
        #expect(error(for: field, text, countryCode: "US") == nil)
    }

    @Test("a postal code that is not a ZIP code is rejected", arguments: Self.postalCodeFields, ["9410", "ABCDE", "SW1A 1AA"])
    func nonZIPPostalCodeIsRejected(field: Field, text: String) {
        #expect(error(for: field, text, countryCode: "US") == .invalidFormat)
    }

    @Test("a malformed ZIP+4 extension is rejected", arguments: Self.postalCodeFields, ["94105-123", "941051234", "94105 1234"])
    func malformedZIPExtensionIsRejected(field: Field, text: String) {
        #expect(error(for: field, text, countryCode: "US") == .invalidFormat)
    }

    // MARK: - International postal code

    @Test("an alphanumeric postal code passes", arguments: Self.postalCodeFields, ["SW1A 1AA", "10115", "K1A-0B1"])
    func internationalPostalCodePasses(field: Field, text: String) {
        #expect(error(for: field, text, countryCode: "GB") == nil)
    }

    @Test(
        "a postal code with a leading or trailing separator or a symbol is rejected",
        arguments: Self.postalCodeFields,
        ["-1234", "1234-", "12#45"]
    )
    func internationalPostalCodeWithBadCharactersIsRejected(field: Field, text: String) {
        #expect(error(for: field, text, countryCode: "GB") == .invalidFormat)
    }

    @Test("the shortest and longest postal codes pass", arguments: Self.postalCodeFields, ["A1B", "1234567890"])
    func internationalPostalCodeAtLengthBoundsPasses(field: Field, text: String) {
        #expect(error(for: field, text, countryCode: "GB") == nil)
    }

    @Test(
        "a postal code one character too short or too long is rejected",
        arguments: Self.postalCodeFields,
        ["A1", "12345678901"]
    )
    func internationalPostalCodeOutsideLengthBoundsIsRejected(field: Field, text: String) {
        #expect(error(for: field, text, countryCode: "GB") == .invalidFormat)
    }

    @Test("a missing country falls back to the international format", arguments: Self.postalCodeFields)
    func missingCountryFallsBackToInternationalFormat(field: Field) {
        #expect(error(for: field, "SW1A 1AA", countryCode: nil) == nil)
        #expect(error(for: field, "SW1A 1AA", countryCode: "US") == .invalidFormat)
    }

    // MARK: - Country code

    @Test("a selected country passes")
    func selectedCountryPasses() {
        #expect(error(for: .countryCode, "US") == nil)
    }

    @Test("a missing country is reported as required")
    func missingCountryIsRequired() {
        #expect(error(for: .countryCode, "") == .required)
    }

    @Test("any non-empty country value is accepted as is", arguments: ["United States", "日本", "??"])
    func nonEmptyCountryValueIsAccepted(text: String) {
        #expect(error(for: .countryCode, text) == nil)
    }

    // MARK: - Names

    @Test(
        "a Latin name passes",
        arguments: Self.nameFields,
        ["John", "Mary-Jane", "O'Brien", "José Müller", "Smith & Sons, Inc."]
    )
    func latinNamePasses(field: Field, text: String) {
        #expect(error(for: field, text) == nil)
    }

    @Test("a name with non-Latin letters or symbols is rejected", arguments: Self.nameFields, ["Γιώργος", "王伟", "john@doe", "John 😀"])
    func nonLatinNameIsRejected(field: Field, text: String) {
        #expect(error(for: field, text) == .nonLatin)
    }

    @Test("a name is capped at 255 characters", arguments: Self.nameFields)
    func nameIsCappedAt255Characters(field: Field) {
        #expect(error(for: field, String(repeating: "a", count: 255)) == nil)
        #expect(error(for: field, String(repeating: "a", count: 256)) == .invalidFormat)
    }

    @Test("an overlong non-Latin name is reported as too long", arguments: Self.nameFields)
    func overlongNonLatinNameIsReportedAsTooLong(field: Field) {
        #expect(error(for: field, String(repeating: "λ", count: 256)) == .invalidFormat)
    }

    @Test(
        "typographic apostrophes, non-breaking spaces and decomposed accents pass",
        arguments: Self.nameFields,
        ["O\u{2019}Brien", "Mary\u{00A0}Jane", "Jose\u{0301}"]
    )
    func typographicNameCharactersPass(field: Field, text: String) {
        #expect(error(for: field, text) == nil)
    }

    // MARK: - Addresses

    @Test(
        "a Latin address passes",
        arguments: Self.addressFields,
        ["221B Baker Street", "Apt. 4/5, #12", "Rue de l'Église (Bât. A)"]
    )
    func latinAddressPasses(field: Field, text: String) {
        #expect(error(for: field, text) == nil)
    }

    @Test(
        "an address with non-Latin letters or symbols is rejected",
        arguments: Self.addressFields,
        ["Οδός Αθηνάς 1", "東京都", "Main St; Apt 2", "Street_1"]
    )
    func nonLatinAddressIsRejected(field: Field, text: String) {
        #expect(error(for: field, text) == .nonLatin)
    }

    @Test("an address is capped at 100 characters", arguments: Self.addressFields)
    func addressIsCappedAt100Characters(field: Field) {
        #expect(error(for: field, String(repeating: "a", count: 100)) == nil)
        #expect(error(for: field, String(repeating: "a", count: 101)) == .invalidFormat)
    }

    @Test("the optional second address line is validated once filled")
    func filledOptionalAddressLineIsValidated() {
        #expect(error(for: .line2, "아파트 5") == .nonLatin)
    }

    // MARK: - Helpers

    private func error(for field: Field, _ text: String, countryCode: String? = nil) -> TangemPayFormField.Error? {
        OfframpFormValidator.error(for: field, in: text, countryCode: countryCode)
    }

    private func email(length: Int) -> String {
        let domain = "@example.com"
        return String(repeating: "a", count: length - domain.count) + domain
    }
}
