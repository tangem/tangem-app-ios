//
//  PreserveRule+objectAddress.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import RegexBuilder

extension PreserveRule {
    /// Preserves object addresses so any broad redaction does not accidentally damage
    /// diagnostically useful instance identity values in logs, for example:
    /// `response: <NSHTTPURLResponse: 0x106f3a120>`
    static let objectAddress = PreserveRule(
        placeholderPrefix: "OBJECT_ADDRESS",
        pattern: Self.objectAddressPattern
    )
}

private extension PreserveRule {
    static let objectAddressPattern = Regex {
        "<"
        swiftTypeName
        ": 0x"
        Repeat(8 ... 16) {
            .hexDigit
        }
        Optionally {
            "; "
            ZeroOrMore {
                NegativeLookahead { ">" }
                CharacterClass.any
            }
        }
        ">"
    }

    static let swiftTypeName = Regex {
        swiftTypeSegment

        ZeroOrMore {
            "."
            swiftTypeSegment
        }
    }

    static let swiftTypeSegment = Regex {
        ChoiceOf {
            swiftTypeThatStartsWithLetter
            swiftTypeThatStartsWithUnderscore
        }
    }

    static let swiftTypeThatStartsWithLetter = Regex {
        CharacterClass(
            "A" ... "Z",
            "a" ... "z"
        )

        ZeroOrMore {
            letterOrNumberOrUnderscore
        }
    }

    static let swiftTypeThatStartsWithUnderscore = Regex {
        "_"

        ZeroOrMore {
            "_"
        }

        letterOrNumber

        ZeroOrMore {
            letterOrNumberOrUnderscore
        }
    }

    static let letterOrNumber = ChoiceOf {
        "A" ... "Z"
        "a" ... "z"
        "0" ... "9"
    }

    static let letterOrNumberOrUnderscore = ChoiceOf {
        "A" ... "Z"
        "a" ... "z"
        "0" ... "9"
        "_"
    }
}
