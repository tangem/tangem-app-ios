//
//  TransactionHistoryValueMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Shared and reusable mapper for both transaction history and aux data mapping.
enum TransactionHistoryValueMapper {
    static func url(fromString string: String?) throws -> URL? {
        guard let urlString = string?.nilIfEmpty else {
            return nil // nil and empty strings are valid values
        }

        if let url = URL(string: urlString) {
            return url
        }

        throw "Failed to create URL from string: \(urlString)"
    }

    static func decimal(fromString string: String?) throws -> Decimal? {
        guard let decimalString = string?.nilIfEmpty else {
            return nil // nil and empty strings are valid values
        }

        if let decimal = Decimal(stringValue: decimalString) {
            return decimal
        }

        throw "Failed to create Decimal from string: \(decimalString)"
    }

    /// Use for columns that are never null, where a missing value is a malformed record rather than an absent one.
    static func decimal(fromString string: String) throws -> Decimal {
        guard let decimal = try decimal(fromString: string as String?) else {
            throw "Failed to create Decimal from string: \(string)"
        }

        return decimal
    }
}
