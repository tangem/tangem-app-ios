//
//  DeeplinkQuery.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Query parameters of a deeplink, read through the rules a link has to satisfy to be worth handling.
///
/// Accessors tell an absent parameter from a malformed one: an absent one comes back as `nil`, a malformed
/// one throws, so the payload initializer turns the whole link away instead of quietly dropping the
/// parameter.
struct DeeplinkQuery {
    private let items: [String: String]

    init(url: URL) {
        items = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .filter { $0.value?.isNotEmpty ?? false }
            .keyedFirst(by: \.name)
            // `queryItems` has already decoded the value, so this decodes it a second time: a value carrying
            // a literal `%` drops out here and reads as absent. Kept as it has always been — the links we
            // publish don't carry one.
            .compactMapValues { $0.value?.removingPercentEncoding } ?? [:]
    }
}

// MARK: - Reading

extension DeeplinkQuery {
    /// Value as it came in the link, with no character rule applied — for parameters that carry
    /// arbitrary text: derivation paths, transaction ids, swap parameters, opaque vendor tokens.
    func unchecked(_ key: String, lowercased: Bool = false) -> String? {
        items[key].map { lowercased ? $0.lowercased() : $0 }
    }

    func optional(_ key: String, lowercased: Bool = false) throws -> String? {
        guard let value = items[key] else {
            return nil
        }

        guard DeeplinkRules.identifier(value) != nil else {
            throw ValidationError.malformedValue(key: key)
        }

        return lowercased ? value.lowercased() : value
    }

    func required(_ key: String, lowercased: Bool = false) throws -> String {
        guard let value = try optional(key, lowercased: lowercased) else {
            throw ValidationError.missingValue(key: key)
        }

        return value
    }

    func optionalNumber(_ key: String) throws -> Int? {
        guard let value = try optional(key) else {
            return nil
        }

        guard let number = DeeplinkRules.number(value) else {
            throw ValidationError.malformedValue(key: key)
        }

        return number
    }

    /// Turns the link away when a parameter this destination doesn't read is malformed.
    func validate(_ keys: String...) throws {
        for key in keys {
            _ = try optional(key)
        }
    }

    /// Turns the link away unless every named parameter is there and well-formed.
    func requireAll(_ keys: String...) throws {
        for key in keys {
            _ = try required(key)
        }
    }
}

// MARK: - Types

extension DeeplinkQuery {
    enum ValidationError: Error {
        case missingValue(key: String)
        case malformedValue(key: String)
    }
}
