//
//  RedactRule+broadHex.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import RegexBuilder

extension RedactRule {
    /// Broadly redacts standalone hex-like blobs that may contain binary or cryptographic data.
    ///
    /// This is a fallback safety rule.
    /// It intentionally prefers false positives over leaking potentially sensitive payloads,
    /// so preserve rules should run before it to exempt known-safe values.
    static let broadHex = RedactRule(
        placeholder: Self.broadHexPlaceholder,
        redact: { input in
            input.replace(Self.broadHexPattern, with: Self.broadHexPlaceholder)
        }
    )
}

private extension RedactRule {
    static let broadHexPlaceholder = "REDACTED_HEX"

    static let broadHexPattern = Regex<Substring> {
        ChoiceOf {
            zeroXPrefixedHexBlob
            unprefixedHexBlob
        }
    }

    static let zeroXPrefixedHexBlob = Regex<Substring> {
        "0"
        ChoiceOf {
            "x"
            "X"
        }
        hexBytePairsBlob
    }

    static let unprefixedHexBlob = Regex<Substring> {
        Lookahead {
            ZeroOrMore {
                ChoiceOf {
                    .hexDigit
                    "-"
                }
            }

            ChoiceOf {
                One("A" ... "F")
                One("a" ... "f")
                "-"
            }
        }

        hexBytePairsBlob
    }

    static let hexBytePairsBlob = Regex<Substring> {
        Repeat(4...) {
            Repeat(count: 2) { .hexDigit }
            Optionally { "-" }
        }
    }
}
