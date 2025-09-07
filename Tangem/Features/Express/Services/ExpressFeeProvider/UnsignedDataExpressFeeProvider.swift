//
//  UnsignedDataExpressFeeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk

struct UnsignedDataExpressFeeProvider {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let feeProvider: any WalletModelFeeProvider

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        feeProvider: any WalletModelFeeProvider
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.feeProvider = feeProvider
    }
}

// MARK: - ExpressFeeProvider

extension UnsignedDataExpressFeeProvider: ExpressFeeProvider {
    func estimatedFee(amount: Decimal) async throws -> ExpressFee.Variants {
        let amount = makeAmount(amount: amount, item: tokenItem)
        let fees = try await feeProvider.estimatedFee(amount: amount).async()
        return try mapToExpressFee(fees: fees)
    }

    func estimatedFee(estimatedGasLimit: Int) async throws -> Fee {
        throw ExpressFeeProviderError.feeNotFound
    }

    func getFee(amount: ExpressAmount, destination: String) async throws -> ExpressFee.Variants {
        switch amount {
        case .transfer(let amount):
            throw ExpressFeeProviderError.feeNotFound
        case .dex(let txValue, let txData):
            try mapToExpressFee(fees: [Fee(Amount.zeroCoin(for: .solana(curve: .secp256k1, testnet: false)))])
        }
    }
}

// MARK: - Private

private extension UnsignedDataExpressFeeProvider {
    func makeAmount(amount: Decimal, item: TokenItem) -> Amount {
        Amount(with: item.blockchain, type: item.amountType, value: amount)
    }

    func mapToExpressFee(fees: [Fee]) throws -> ExpressFee.Variants {
        return .single(fees[0])
    }
}
