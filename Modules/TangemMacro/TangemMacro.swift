//
//  TangemMacro.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// A freestanding expression macro that produces a string representation of the provided value.
///
/// This macro defers to the implementation in `TangemMacroImplementation.StringifyMacro` to
/// generate a human-readable string, typically useful for debugging, logging, or diagnostics.
///
/// Usage:
/// ```swift
/// let number = 42
/// let text: String = #stringify(number)
/// // e.g. "number = 42" or an implementation-defined representation
/// ```
///
/// - Parameter value: The value to stringify. Works with any type `T`.
/// - Returns: A `String` produced by the macro implementation that represents the input value.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (String) = #externalMacro(
    module: "TangemMacroImplementation",
    type: "StringifyMacro"
)

/// A macro that synthesizes boolean flags for each enum case, enabling easy checks like `isCaseName`.
///
/// When applied to an `enum`, this macro generates computed properties for each case in the form
/// `is<CaseName>` that return `true` when `self` matches the case, regardless of associated values.
///
/// Usage:
/// ```swift
/// [REDACTED_USERNAME]
/// enum NetworkState {
///     case idle
///     case loading
///     case failed(Error)
/// }
///
/// let state: NetworkState = .failed(MyError())
/// state.isIdle      // false
/// state.isLoading   // false
/// state.isFailed    // true
/// ```
///
/// Notes:
/// - Associated values are ignored when evaluating the generated flags.
/// - The generated property names are derived from the case names using UpperCamelCase after the `is` prefix.
@attached(member, names: arbitrary)
public macro CaseFlagable() = #externalMacro(
    module: "TangemMacroImplementation",
    type: "CaseFlagableMacro"
)

/// A macro that adds `RawCaseNameRepresentable` conformance and synthesizes a raw identifier for each enum case.
///
/// When applied to an `enum`, this macro generates a computed property `rawCaseValue`
/// (and/or other helper members as defined by the implementation) that returns a stable,
/// string-based identifier for the current case, independent of associated values.
/// The macro also makes the enum conform to `RawCaseNameRepresentable`.
///
/// Usage:
/// ```swift
/// [REDACTED_USERNAME]
/// enum PaymentState {
///     case idle
///     case processing(amount: Decimal)
///     case failed(error: Error)
/// }
///
/// let state: PaymentState = .processing(amount: 10)
/// // state.rawCaseValue == "processing"
/// ```
///
/// Notes:
/// - Associated values are ignored when producing the identifier.
/// - The exact member names and visibility are defined by the macro implementation in
///   `TangemMacroImplementation.RawCaseNameMacro`.
/// - Applying this macro will add `RawCaseNameRepresentable` conformance to the enum.
@attached(extension, conformances: RawCaseNameRepresentable, names: named(rawCaseValue))
public macro RawCaseName() = #externalMacro(
    module: "TangemMacroImplementation",
    type: "RawCaseNameMacro"
)
