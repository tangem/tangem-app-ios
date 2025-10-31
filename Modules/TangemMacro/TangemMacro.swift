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
