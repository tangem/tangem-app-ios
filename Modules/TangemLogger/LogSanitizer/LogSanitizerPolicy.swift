//
//  LogSanitizerPolicy.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Defines which preserve and redact rules are used by ``LogSanitizer``.
///
/// A policy controls both the composition and the execution order of rules in the sanitization pipeline.
struct LogSanitizerPolicy {
    /// Rules that temporarily protect known-safe fragments before redaction.
    let preserveRules: [PreserveRule]

    /// Rules that redact sensitive content after preserve rules have run.
    let redactRules: [RedactRule]
}

extension LogSanitizerPolicy {
    /// Production sanitization policy used for persisted logs.
    static let production = LogSanitizerPolicy(
        preserveRules: [
            .objectAddress,
            .iso8601Timestamp,
            .swapPayload,
        ],
        redactRules: [
            .sensitiveKey,
            .broadHex,
        ]
    )
}
