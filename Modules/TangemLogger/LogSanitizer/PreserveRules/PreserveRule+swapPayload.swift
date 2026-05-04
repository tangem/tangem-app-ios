//
//  PreserveRule+swapPayload.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import RegexBuilder

extension PreserveRule {
    /// Preserves selected swap payload key/value pairs so broad hex redaction does not
    /// damage known-safe identifiers and addresses embedded in swap API logs, for example:
    /// `{"txId":"23b0ba60-8f61-4917-83e7-0464f97f1d55","fromAddress":"0x0f0632254b1b45b835e5911E729871667E91BE12"}`
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
