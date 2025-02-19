//
//  LimitsResponseParser.swift
//  TangemVisa
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct LimitsResponseParser {
    private let responseLength = 960
    private let singleValueLength = 64
    private let itemsForEachLimit = 7
    private let amountsCount = 5
    private let numberOfLimits = 3
    private let parser = EthereumDataParser()

    func parseResponse(_ response: String, decimalCount: Int) throws -> VisaLimits {
        let clearedResponse = response.removeHexPrefix()
        guard clearedResponse.count == responseLength else {
            throw VisaParserError.limitsResponseWrongLength
        }
        let chunks = EthereumDataParser().split(string: clearedResponse)

        return try parseResponse(chunks: chunks, decimalCount: decimalCount)
    }

    func parseResponse(chunks: [String], decimalCount: Int) throws -> VisaLimits {
        var limitsStrings = chunks
        guard limitsStrings.count == (itemsForEachLimit * 2 + 1) else {
            throw VisaParserError.limitsResponseWrongLength
        }

        let timeIntervalWhenLimitsChange = parser.getDateSince1970(string: limitsStrings.removeLast())
        let oldLimit = try parseLimit(Array(limitsStrings[0 ..< itemsForEachLimit]), decimalCount: decimalCount)
        let newLimit = try parseLimit(Array(limitsStrings[itemsForEachLimit ..< limitsStrings.count]), decimalCount: decimalCount)

        return VisaLimits(
            oldLimit: oldLimit,
            newLimit: newLimit,
            changeDate: timeIntervalWhenLimitsChange
        )
    }

    private func parseLimit(_ chunks: [String], decimalCount: Int) throws -> VisaLimit {
        var limitItems = chunks
        chunks.forEach { print($0) }
        guard limitItems.count == itemsForEachLimit else {
            throw VisaParserError.limitWrongSingleLimitItemsCount
        }

        let limitDurationSeconds = parser.getTimeInSeconds(string: limitItems.removeLast())
        let dueDate = parser.getDateSince1970(string: limitItems.removeLast())

        var values = limitItems.map { parser.getDecimal(string: $0, decimalsCount: decimalCount) }

        guard values.count == amountsCount else {
            throw VisaParserError.limitWrongSingleLimitAmountsCount
        }

        return VisaLimit(
            expirationDate: dueDate,
            limitDurationSeconds: limitDurationSeconds,
            singleTransaction: values.removeFirst(),
            otpLimit: values.removeFirst(),
            spentOTPAmount: values.removeFirst(),
            noOTPLimit: values.removeFirst(),
            spentNoOTPAmount: values.removeFirst()
        )
    }
}
