//
//  PreserveRule+idempotencyKey.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import RegexBuilder

extension PreserveRule {
    /// Preserves the SHA-256 hex value emitted alongside the `Idempotency-Key-New` label
    /// in `CommonTangemPayAuthorizationService` diagnostic logs, so the broad hex redactor
    /// doesn't collapse it to `REDACTED_HEX`.
    static let idempotencyKey = PreserveRule(
        placeholderPrefix: "IDEMPOTENCY_KEY",
        pattern: Self.idempotencyKeyPattern
    )
}

private extension PreserveRule {
    static let idempotencyKeyPattern = Regex<Substring> {
        "Idempotency-Key-New: "
        Repeat(count: 64) { .hexDigit }
    }
}
