//
//  TangemMacro.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// A macro that synthesizes a pattern-matching operator implementation which ignores associated values when matching enum cases.
///
/// Usage:
/// ```swift
/// [REDACTED_USERNAME]
/// enum MyEnum {
///   case a(Int)
///   case b(String, Double)
///   case c
/// }
///
/// let value = MyEnum.a(42)
/// MyEnum.a(12) == value is `true`
/// ```
@attached(member, names: arbitrary)
public macro AssociatedValueInsensitiveEquatable() = #externalMacro(
    module: "TangemMacroImplementation",
    type: "AssociatedValueInsensitiveEquatableMarco"
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
