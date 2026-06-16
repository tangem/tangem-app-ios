//
//  PreserveRule+tokenContractAddress.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import RegexBuilder

extension PreserveRule {
    /// Preserves the `contractAddress` JSON field value so broad hex redaction does not
    /// damage token contract identifiers in account/user-tokens API logs, for example:
    /// `{"networkId":"avalanche","contractAddress":"0xaf88d065e77c8cc2239327c5edb3a432268e5831","id":"usd-coin"}`
    static let tokenContractAddress = PreserveRule(
        placeholderPrefix: "TOKEN_CONTRACT_ADDRESS",
        pattern: Self.tokenContractAddressPattern
    )
}

private extension PreserveRule {
    static let tokenContractAddressPattern = Regex {
        quote
        "contractAddress"
        quote
        optionalWhitespace
        ":"
        optionalWhitespace
        quote
        fieldValue
        quote
    }

    static let fieldValue = Regex {
        ZeroOrMore {
            NegativeLookahead {
                ChoiceOf {
                    quote
                    "\n"
                }
            }
            CharacterClass.any
        }
    }

    static let quote = "\""

    static let optionalWhitespace = ZeroOrMore {
        ChoiceOf {
            " "
            "\t"
        }
    }
}
