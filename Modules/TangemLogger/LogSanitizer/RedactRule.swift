//
//  RedactRule.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// A single redaction step in the log sanitization pipeline.
///
/// The rule replaces sensitive fragments in a log string with ``placeholder``.
struct RedactRule {
    /// Placeholder used by the rule when replacing sensitive content.
    let placeholder: String

    /// Applies the rule to the provided log string.
    let redact: (inout String) -> Void
}
