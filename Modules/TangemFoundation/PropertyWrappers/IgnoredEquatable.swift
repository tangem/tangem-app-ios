//
//  IgnoredEquatable.swift
//  TangemFoundation
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

/// A property wrapper that opts the wrapped value out of participating in
/// synthesized `Equatable` and `Hashable` conformances.
///
/// Useful for properties like closures, subjects, delegates, etc. that
/// should not affect equality or hashing of the parent type.
///
/// Example:
///
///     struct State: Equatable, Hashable {
///         let title: String
///         [REDACTED_USERNAME] var onTap: () -> Void = {}
///     }
///
/// `State` can synthesize `Equatable`/`Hashable` and comparisons will ignore `onTap`.
@propertyWrapper
public struct IgnoredEquatable<Value> {
    public var wrappedValue: Value

    @inlinable
    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}

extension IgnoredEquatable: Equatable {
    @inlinable
    public static func == (lhs: IgnoredEquatable<Value>, rhs: IgnoredEquatable<Value>) -> Bool {
        // Always equal, so the wrapped value is ignored in parent comparisons
        true
    }
}

extension IgnoredEquatable: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) { /* no-op */ }
}
