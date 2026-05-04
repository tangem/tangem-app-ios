//
//  LogSanitizer.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

/// Redacts sensitive content in log strings according to a provided policy.
///
/// The sanitizer applies preserve rules first, then redact rules,
/// and finally restores preserved values back into the resulting log string.
enum LogSanitizer {
    /// Redacts sensitive content in a log string
    /// while preserving explicitly allowed values defined by the provided policy.
    /// - Parameters:
    ///   - value: Original log string to process.
    ///   - policy: Policy that defines which fragments should be preserved and which should be redacted.
    /// - Returns: A transformed log string with preserved values restored and sensitive content redacted.
    static func sanitize(_ value: String, policy: LogSanitizerPolicy) -> String {
        var sanitized = value
        var preserved = [[Substring]]()

        for preserveRule in policy.preserveRules {
            let preservedValues = preserveRule.preserve(&sanitized)
            preserved.append(preservedValues)
        }

        for redactRule in policy.redactRules {
            redactRule.redact(&sanitized)
        }

        for (preserveRule, preservedValues) in zip(policy.preserveRules, preserved) {
            preserveRule.restore(preservedValues, &sanitized)
        }

        return sanitized
    }
}
