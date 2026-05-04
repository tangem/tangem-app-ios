//
//  RedactRule+sensitiveKey.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import RegexBuilder

extension RedactRule {
    /// Redacts values associated with known sensitive keys.
    ///
    /// The rule keeps the original key/value structure intact and replaces only
    /// the sensitive value with `REDACTED_SENSITIVE_KEY`.
    ///
    /// Already-redacted values are ignored.
    static let sensitiveKey = RedactRule(
        placeholder: Self.sensitiveKeyPlaceholder,
        redact: { input in
            input.replace(
                Self.sensitiveKeyPattern,
                with: { match in
                    match.1 + Self.sensitiveKeyPlaceholder + match.3
                }
            )
        }
    )
}

private extension RedactRule {
    static let sensitiveKeyPlaceholder = "REDACTED_SENSITIVE_KEY"

    static let sensitiveKeyPattern = Regex<(Substring, Substring, Substring, Substring)> {
        apiKeyPrefix
        apiKeyNegativeLookahead
        valueCapture
        optionalQuoteSuffix
    }

    static let apiKeyPrefix = Capture {
        optionalQuote
        keyName
        optionalQuote
        optionalWhitespace
        keyValueSeparator
        optionalWhitespace
        optionalQuote
    }

    static let apiKeyNegativeLookahead = NegativeLookahead {
        Self.sensitiveKeyPlaceholder
        Anchor.wordBoundary
    }

    static let valueCapture = Capture {
        OneOrMore {
            ChoiceOf {
                "A" ... "Z"
                "a" ... "z"
                "0" ... "9"
                "."
                "_"
                "-"
                "/"
                "+"
                "="
            }
        }
    }

    static let optionalQuoteSuffix = Capture { optionalQuote }

    static let keyName = Regex {
        ChoiceOf {
            "api-key"
            "x-api-key"
            "api_key"
            "apikey"
            "access-token"
            "access_token"
            "accesstoken"
            "auth"
            "key"
        }
    }
    .ignoresCase()

    static let optionalQuote = Optionally { CharacterClass.anyOf(#""'"#) }

    static let optionalWhitespace = ZeroOrMore(.whitespace)

    static let keyValueSeparator = ChoiceOf {
        ":"
        "="
    }
}
