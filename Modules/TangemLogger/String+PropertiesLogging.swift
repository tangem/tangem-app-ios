//
//  String+PropertiesLogging.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public extension AnyKeyPath {
    /// Returns the last component of a key path string representation.
    ///
    /// This is intended for log formatting where field names should stay tied to real Swift properties
    /// instead of being duplicated as string literals.
    ///
    /// ```swift
    /// struct Transaction {
    ///     let txID: String
    /// }
    /// struct Request {
    ///     let requestID: String?
    ///     let transaction: Transaction
    /// }
    ///
    /// let requestIDKeyPath = \Request.requestID
    /// let txIDKeyPath = \Request.transaction.txID
    ///
    /// print(requestIDKeyPath.propertyName)    // requestID
    /// print(txIDKeyPath.propertyName)         // txID
    /// ```
    var propertyName: String {
        String("\(self)".split(separator: ".").last ?? "")
    }
}

public extension String {
    /// Appends a formatted log line for a non-optional property.
    ///
    /// The property name is derived from the key path, and the value is formatted with `String(describing:)`.
    ///
    /// - Warning: If the selected property is a type that contains optional fields, Swift's synthesized
    ///   description may still include values like `Optional("value")`.
    ///   Use key paths to leaf properties when optional formatting matters.
    ///
    /// ```swift
    /// let request = Request(transaction: Transaction(txID: "23b0ba60-8f61-4917-83e7-0464f97f1d55"))
    /// let log = "Exchange sent request payload:"
    ///     .appendingLogProperty(\.transaction.txID, of: request)
    ///
    /// // Exchange sent request payload:
    /// // "txID": "23b0ba60-8f61-4917-83e7-0464f97f1d55"
    /// ```
    func appendingLogProperty<Root, Value>(_ keyPath: KeyPath<Root, Value>, of instance: Root) -> String {
        let propertyName = keyPath.propertyName
        let value = String(describing: instance[keyPath: keyPath])

        return formatted(propertyName, and: value)
    }

    /// Appends a formatted log line for an optional property.
    ///
    /// The property name is derived from the key path. Non-nil values are unwrapped before formatting,
    /// so the log contains `"value"` instead of `Optional("value")`. Nil values are written as `"nil"`.
    ///
    /// - Warning: If the selected property is a type that contains optional fields, Swift's synthesized
    ///   description may still include values like `Optional("value")`.
    ///   Use key paths to leaf properties when optional formatting matters.
    ///
    /// ```swift
    /// let response = Response(transaction: Transaction(externalTxID: nil))
    /// let log = "Exchange status response payload:"
    ///     .appendingLogProperty(\.transaction.externalTxID, of: response)
    ///
    /// // Exchange status response payload:
    /// // "externalTxID": "nil"
    /// ```
    func appendingLogProperty<Root, Value>(_ keyPath: KeyPath<Root, Value?>, of instance: Root) -> String {
        let propertyName = keyPath.propertyName
        let value = instance[keyPath: keyPath].map(String.init(describing:)) ?? "nil"

        return formatted(propertyName, and: value)
    }

    private func formatted(_ propertyName: String, and value: String) -> String {
        self + "\n\"\(propertyName)\": \"\(value)\""
    }
}
