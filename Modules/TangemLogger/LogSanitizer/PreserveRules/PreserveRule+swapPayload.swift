//
//  PreserveRule+swapPayload.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import RegexBuilder

extension PreserveRule {
    /// Preserves exact swap DTO log payloads so broad hex redaction does not damage known-safe
    /// identifiers and addresses from explicitly whitelisted swap fields.
    static let swapPayload = PreserveRule(
        placeholderPrefix: "SWAP_PAYLOAD",
        pattern: Self.swapPayloadPattern
    )
}

private extension PreserveRule {
    static let swapPayloadPattern = Regex {
        ChoiceOf {
            exchangeDataRequest
            exchangeDataResponse
            exchangeStatusResponse
            exchangeSentRequest
            exchangeSentResponse
            decodedTransactionDetails
        }
    }

    static let exchangeDataRequest = Regex {
        "Exchange data request payload:"
        logField("fromAddress")
        logField("fromContractAddress")
        logField("fromNetwork")
        logField("toContractAddress")
        logField("toNetwork")
        logField("toDecimals")
        logField("fromAmount")
        logField("toAmount")
        logField("fromDecimals")
        logField("providerId")
        logField("rateType")
        logField("toAddress")
        logField("refundAddress")
    }

    static let exchangeDataResponse = Regex {
        "Exchange data response payload:"
        logField("txId")
        logField("fromAmount")
        logField("fromDecimals")
        logField("toAmount")
        logField("toDecimals")
        logField("payTill")
    }

    static let exchangeStatusResponse = Regex {
        "Exchange status response payload:"
        logField("txId")
        logField("providerId")
        logField("fromAddress")
        logField("payinAddress")
        logField("payinExtraId")
        logField("payoutAddress")
        logField("refundAddress")
        logField("refundExtraId")
        logField("rateType")
        logField("status")
        logField("externalTxId")
        logField("externalTxUrl")
        logField("payinHash")
        logField("payoutHash")
        logField("refundNetwork")
        logField("refundContractAddress")
        logField("createdAt")
        logField("updatedAt")
        logField("payTill")
        logField("averageDuration")
        logField("fromContractAddress")
        logField("fromNetwork")
        logField("fromDecimals")
        logField("fromAmount")
        logField("toContractAddress")
        logField("toNetwork")
        logField("toDecimals")
        logField("toAmount")
        logField("toActualAmount")
    }

    static let exchangeSentRequest = Regex {
        "Exchange sent request payload:"
        logField("txHash")
        logField("txId")
        logField("fromNetwork")
        logField("fromAddress")
        logField("payinAddress")
        logField("payinExtraId")
    }

    static let exchangeSentResponse = Regex {
        "Exchange sent response payload:"
        logField("txId")
        logField("status")
    }

    static let decodedTransactionDetails = Regex {
        "Exchange data decoded transaction details payload:"
        logField("requestId")
        logField("txType")
        logField("txFrom")
        logField("txTo")
        logField("txExtraId")
        logField("txValue")
        logField("otherNativeFee")
        logField("gas")
        logField("externalTxId")
        logField("externalTxUrl")
        logField("payoutAddress")
        logField("payoutExtraId")
    }

    static func logField(_ fieldName: Substring) -> Regex<Substring> {
        Regex {
            "\n"
            quote
            fieldName
            quote
            ": "
            quote
            fieldValue
            quote
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
}
