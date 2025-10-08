//
//  LogsSanitizer.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

// [REDACTED_TODO_COMMENT]

enum LogsSanitizer {
    static let apiKeyFields = [
        "api-key",
        "x-api-key",
        "api_key",
        "apikey",
        "access-token",
        "access_token",
        "auth",
        "token",
        "key",
    ]

    static func sanitize(_ value: String) -> String {
        var sanitized = value

        // 1. Redact api keys
        let fieldAlternation = apiKeyFields
            .map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")

        let apiKeyPattern = "(?i)\\b(\(fieldAlternation))\\s*[:=]\\s*(['\"]?)(?!REDACTED)[A-Za-z0-9._\\-]+\\2"

        sanitized = sanitized.replacingOccurrences(
            of: apiKeyPattern,
            with: "$1=REDACTED",
            options: .regularExpression
        )

        // 2. Redact hex data
        let hexDataPattern = #"(0[xX])?(?:[A-Fa-f0-9]{2}-?){4,}"#

        sanitized = sanitized.replacingOccurrences(
            of: hexDataPattern,
            with: "REDACTED",
            options: .regularExpression
        )

        return sanitized
    }
}
