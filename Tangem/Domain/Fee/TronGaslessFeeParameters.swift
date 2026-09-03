//
//  TronGaslessFeeParameters.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct TronGaslessFeeParameters: FeeParameters {
    let quoteId: String
    let request: TronGaslessQuoteRequest
    let feeRecipient: String
    let compensationToken: String
    let compensationAmountRaw: String
    let expiresAt: Date
    let energy: Int
    let bandwidth: Int
    let trxCost: String
}

extension TronGaslessFeeParameters {
    static let expirationBuffer: TimeInterval = 60
}

struct TronGaslessQuoteRequest: Equatable {
    let sourceAddress: String
    let destinationAddress: String
    let tokenContractAddress: String
    let amountRaw: String
    let feeTokenContractAddress: String

    func matches(transaction: BSDKTransaction, feeToken: BSDKToken) -> Bool {
        guard sourceAddress == transaction.sourceAddress else {
            return false
        }

        return matches(
            amount: transaction.amount,
            destinationAddress: transaction.destinationAddress,
            feeToken: feeToken
        )
    }

    func matches(amount: BSDKAmount, destinationAddress: String, feeToken: BSDKToken) -> Bool {
        guard let tokenContractAddress = amount.type.token?.contractAddress,
              let amountRaw = amount.bigUIntValue?.description else {
            return false
        }

        return self.destinationAddress == destinationAddress
            && self.tokenContractAddress == tokenContractAddress
            && self.amountRaw == amountRaw
            && feeTokenContractAddress == feeToken.contractAddress
    }
}
