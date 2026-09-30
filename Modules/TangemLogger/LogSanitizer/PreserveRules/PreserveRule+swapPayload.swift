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

/// Patterns are regex literals rather than `RegexBuilder` compositions: the Swift 6.4.0 runtime shipped
/// with iOS 27.0 corrupts a builder regex when a string literal is followed by an embedded regex that also
/// starts with a literal, which made this rule match arbitrary text. `ChoiceOf` only alternates and is unaffected.
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

    // swiftformat:disable indent
    // SwiftFormat misreads quotes and escaped brackets inside multi-line regex literals and breaks their indentation.

    static let exchangeDataRequest = #/
        (?s)
        Exchange\ data\ request\ payload:
        \n"fromAddress":\ "(?:(?!"|\n).)*"
        \n"fromContractAddress":\ "(?:(?!"|\n).)*"
        \n"fromNetwork":\ "(?:(?!"|\n).)*"
        \n"toContractAddress":\ "(?:(?!"|\n).)*"
        \n"toNetwork":\ "(?:(?!"|\n).)*"
        \n"toDecimals":\ "(?:(?!"|\n).)*"
        \n"fromAmount":\ "(?:(?!"|\n).)*"
        \n"toAmount":\ "(?:(?!"|\n).)*"
        \n"fromDecimals":\ "(?:(?!"|\n).)*"
        \n"providerId":\ "(?:(?!"|\n).)*"
        \n"rateType":\ "(?:(?!"|\n).)*"
        \n"toAddress":\ "(?:(?!"|\n).)*"
        \n"refundAddress":\ "(?:(?!"|\n).)*"
        /#

    static let exchangeDataResponse = #/
        (?s)
        Exchange\ data\ response\ payload:
        \n"txId":\ "(?:(?!"|\n).)*"
        \n"fromAmount":\ "(?:(?!"|\n).)*"
        \n"fromDecimals":\ "(?:(?!"|\n).)*"
        \n"toAmount":\ "(?:(?!"|\n).)*"
        \n"toDecimals":\ "(?:(?!"|\n).)*"
        \n"payTill":\ "(?:(?!"|\n).)*"
        /#

    static let exchangeStatusResponse = #/
        (?s)
        Exchange\ status\ response\ payload:
        \n"txId":\ "(?:(?!"|\n).)*"
        \n"providerId":\ "(?:(?!"|\n).)*"
        \n"fromAddress":\ "(?:(?!"|\n).)*"
        \n"payinAddress":\ "(?:(?!"|\n).)*"
        \n"payinExtraId":\ "(?:(?!"|\n).)*"
        \n"payoutAddress":\ "(?:(?!"|\n).)*"
        \n"refundAddress":\ "(?:(?!"|\n).)*"
        \n"refundExtraId":\ "(?:(?!"|\n).)*"
        \n"rateType":\ "(?:(?!"|\n).)*"
        \n"status":\ "(?:(?!"|\n).)*"
        \n"externalTxId":\ "(?:(?!"|\n).)*"
        \n"externalTxUrl":\ "(?:(?!"|\n).)*"
        \n"payinHash":\ "(?:(?!"|\n).)*"
        \n"payoutHash":\ "(?:(?!"|\n).)*"
        \n"refundNetwork":\ "(?:(?!"|\n).)*"
        \n"refundContractAddress":\ "(?:(?!"|\n).)*"
        \n"createdAt":\ "(?:(?!"|\n).)*"
        \n"updatedAt":\ "(?:(?!"|\n).)*"
        \n"payTill":\ "(?:(?!"|\n).)*"
        \n"averageDuration":\ "(?:(?!"|\n).)*"
        \n"fromContractAddress":\ "(?:(?!"|\n).)*"
        \n"fromNetwork":\ "(?:(?!"|\n).)*"
        \n"fromDecimals":\ "(?:(?!"|\n).)*"
        \n"fromAmount":\ "(?:(?!"|\n).)*"
        \n"toContractAddress":\ "(?:(?!"|\n).)*"
        \n"toNetwork":\ "(?:(?!"|\n).)*"
        \n"toDecimals":\ "(?:(?!"|\n).)*"
        \n"toAmount":\ "(?:(?!"|\n).)*"
        \n"toActualAmount":\ "(?:(?!"|\n).)*"
        /#

    static let exchangeSentRequest = #/
        (?s)
        Exchange\ sent\ request\ payload:
        \n"txHash":\ "(?:(?!"|\n).)*"
        \n"txId":\ "(?:(?!"|\n).)*"
        \n"fromNetwork":\ "(?:(?!"|\n).)*"
        \n"fromAddress":\ "(?:(?!"|\n).)*"
        \n"payinAddress":\ "(?:(?!"|\n).)*"
        \n"payinExtraId":\ "(?:(?!"|\n).)*"
        /#

    static let exchangeSentResponse = #/
        (?s)
        Exchange\ sent\ response\ payload:
        \n"txId":\ "(?:(?!"|\n).)*"
        \n"status":\ "(?:(?!"|\n).)*"
        /#

    static let decodedTransactionDetails = #/
        (?s)
        Exchange\ data\ decoded\ transaction\ details\ payload:
        \n"requestId":\ "(?:(?!"|\n).)*"
        \n"txType":\ "(?:(?!"|\n).)*"
        \n"txFrom":\ "(?:(?!"|\n).)*"
        \n"txTo":\ "(?:(?!"|\n).)*"
        \n"txExtraId":\ "(?:(?!"|\n).)*"
        \n"txValue":\ "(?:(?!"|\n).)*"
        \n"otherNativeFee":\ "(?:(?!"|\n).)*"
        \n"gas":\ "(?:(?!"|\n).)*"
        \n"externalTxId":\ "(?:(?!"|\n).)*"
        \n"externalTxUrl":\ "(?:(?!"|\n).)*"
        \n"payoutAddress":\ "(?:(?!"|\n).)*"
        \n"payoutExtraId":\ "(?:(?!"|\n).)*"
        /#
    // swiftformat:enable indent
}
