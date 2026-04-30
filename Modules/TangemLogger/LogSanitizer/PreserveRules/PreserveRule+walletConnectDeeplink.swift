//
//  PreserveRule+walletConnectDeeplink.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import RegexBuilder

extension PreserveRule {
    /// Preserves WalletConnect deeplinks carried in Tangem URLs so the encoded WalletConnect
    /// URI survives broad hex redaction, for example:
    /// `tangem://wc?uri=wc%3A08018d08454c05ed4a5714cf74df3279f95648a9c216b68380599f9120a03a68%402%3FexpiryTimestamp%3D1777542409%26relay-protocol%3Dirn%26symKey%3Da5f72962c597402f36964378228212aad395b1fb705f6259ae6bf96aef944c40`
    static let walletConnectDeeplink = PreserveRule(
        placeholderPrefix: "WC_DEEPLINK",
        pattern: Self.walletConnectDeeplinkPattern
    )
}

private extension PreserveRule {
    static let walletConnectDeeplinkPattern = Regex {
        "tangem://wc?uri=wc"
        encodedColon
        encodedValue(until: encodedAt)
        encodedAt
        encodedValue(until: encodedQuestionMark)
        encodedQuestionMark
        encodedQueryItem
        ZeroOrMore {
            encodedAmpersand
            encodedQueryItem
        }
        Lookahead {
            deeplinkBoundary
        }
    }

    static let encodedQueryItem = Regex {
        ChoiceOf {
            encodedQueryItem(named: "relay-protocol")
            encodedQueryItem(named: "symKey")
            encodedQueryItem(named: "expiryTimestamp", value: OneOrMore(.digit))
            encodedQueryItem(named: "relay-data")
            encodedQueryItem(named: "methods")
        }
    }

    static func encodedQueryItem(named key: String) -> Regex<Substring> {
        encodedQueryItem(named: key, value: encodedQueryItemValue)
    }

    static func encodedQueryItem(named key: String, value: some RegexComponent) -> Regex<Substring> {
        Regex {
            key
            encodedEquals
            value
        }
    }

    static func encodedValue(until separator: some RegexComponent) -> Regex<Substring> {
        Regex {
            OneOrMore {
                NegativeLookahead {
                    separator
                }
                CharacterClass.any
            }
        }
    }

    static let encodedQueryItemValue = Regex {
        OneOrMore {
            NegativeLookahead {
                ChoiceOf {
                    encodedAmpersand
                    deeplinkBoundary
                }
            }
            CharacterClass.any
        }
    }

    static let deeplinkBoundary = Regex {
        ChoiceOf {
            Anchor.endOfSubject
            " "
            "\t"
            "\n"
            "\r"
            "\""
            "'"
            ")"
            "]"
            ">"
        }
    }

    static let encodedColon = "%3A"
    static let encodedAt = "%40"
    static let encodedQuestionMark = "%3F"
    static let encodedAmpersand = "%26"
    static let encodedEquals = "%3D"
}
