//
//  PreserveRule+swapPayload.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import RegexBuilder

extension PreserveRule {
    static let swapPayload = PreserveRule(
        placeholderPrefix: "SWAP_PAYLOAD",
        pattern: Self.swapPayloadPattern
    )
}

private extension PreserveRule {
    static let swapPayloadPattern = Regex {
        quote
        fieldName
        quote
        optionalWhitespace
        ":"
        optionalWhitespace
        quote
        fieldValue
        quote
    }

    static let fieldName = Regex {
        ChoiceOf {
            "txId"
            "fromAddress"
            "payinAddress"
            "payoutAddress"
            "refundAddress"
            "txHash"
            "fromContractAddress"
            "toContractAddress"
        }
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
