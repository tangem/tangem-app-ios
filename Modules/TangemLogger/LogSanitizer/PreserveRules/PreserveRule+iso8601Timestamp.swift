//
//  PreserveRule+iso8601Timestamp.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import RegexBuilder

extension PreserveRule {
    /// Preserves ISO 8601 UTC timestamps so any broad redaction does not accidentally damage them in logs, for example:
    /// `{"timeline":{"start":"2026-12-24T00:00:00.000Z","end":"1970-01-01T12:34:56Z"}}`
    static let iso8601Timestamp = PreserveRule(
        placeholderPrefix: "ISO8601_TIMESTAMP",
        pattern: Self.iso8601TimestampPattern
    )
}

private extension PreserveRule {
    static let iso8601TimestampPattern = Regex {
        year
        hyphenSeparator
        month
        hyphenSeparator
        day
        dateTimeSeparator
        hour
        colonSeparator
        minute
        colonSeparator
        second
        fractionalSeconds
        utcDesignator
    }

    static let year = Regex {
        Repeat(count: 4) { One(.digit) }
    }

    static let month = Regex {
        ChoiceOf {
            Regex {
                "0"
                One("1" ... "9")
            }
            Regex {
                "1"
                One("0" ... "2")
            }
        }
    }

    static let day = Regex {
        ChoiceOf {
            Regex {
                "0"
                One("1" ... "9")
            }

            Regex {
                ChoiceOf {
                    "1"
                    "2"
                }
                One(.digit)
            }

            Regex {
                "3"
                ChoiceOf {
                    "0"
                    "1"
                }
            }
        }
    }

    static let hour = Regex {
        ChoiceOf {
            Regex {
                ChoiceOf {
                    "0"
                    "1"
                }
                One(.digit)
            }
            Regex {
                "2"
                ChoiceOf {
                    "0"
                    "1"
                    "2"
                    "3"
                }
            }
        }
    }

    static let minute = Regex {
        zeroToSixty
    }

    static let second = Regex {
        zeroToSixty
    }

    static let zeroToSixty = Regex {
        ChoiceOf {
            Regex {
                ChoiceOf {
                    "0"
                    "1"
                    "2"
                    "3"
                    "4"
                    "5"
                }
                One(.digit)
            }
        }
    }

    static let fractionalSeconds = Regex {
        Optionally {
            "."
            OneOrMore(.digit)
        }
    }

    static let dateTimeSeparator = "T"
    static let utcDesignator = "Z"

    static let hyphenSeparator = "-"
    static let colonSeparator = ":"
}
