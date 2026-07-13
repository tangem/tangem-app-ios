//
//  CommonBitcoinTokenFeeLoader.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CommonBitcoinTokenFeeLoader {
    let tokenItem: TokenItem
    let tokenFeeLoader: any TokenFeeLoader
}

// MARK: - BitcoinTokenFeeLoader

extension CommonBitcoinTokenFeeLoader: BitcoinTokenFeeLoader {
    func getFee(psbtBase64: String) async throws -> [BSDKFee] {
        let satoshi = try BitcoinPsbtSigningBuilder.fee(psbtBase64: psbtBase64)
        let value = Decimal(satoshi) / tokenItem.blockchain.decimalValue
        let amount = BSDKAmount(with: tokenItem.blockchain, type: .coin, value: value)
        return [BSDKFee(amount)]
    }
}

// MARK: - TokenFeeLoader Proxy

extension CommonBitcoinTokenFeeLoader: TokenFeeLoader {
    var isGasless: Bool { false }

    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] {
        try await tokenFeeLoader.estimatedFee(amount: amount)
    }

    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] {
        try await tokenFeeLoader.getFee(amount: amount, destination: destination)
    }
}
