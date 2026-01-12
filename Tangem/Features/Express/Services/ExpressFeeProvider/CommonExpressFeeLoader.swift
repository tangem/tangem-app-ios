//
//  CommonExpressFeeLoader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk
import BigInt

struct CommonExpressFeeLoader {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let feeLoader: any TokenFeeLoader

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        feeLoader: any TokenFeeLoader,
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.feeLoader = feeLoader
    }
}

// MARK: - ExpressFeeProvider

extension CommonExpressFeeLoader: ExpressFeeProvider {
    func estimatedFee(amount: Decimal) async throws -> ExpressFee.Variants {
        let fees = try await feeLoader.estimatedFee(amount: amount)
        return try mapToExpressFee(fees: fees)
    }

    func estimatedFee(estimatedGasLimit: Int) async throws -> Fee {
        let fee = try await feeLoader.asEthereumTokenFeeLoader().estimatedFee(
            estimatedGasLimit: estimatedGasLimit
        )
        return fee
    }

    func getFee(amount: ExpressAmount, destination: String) async throws -> ExpressFee.Variants {
        switch (amount, tokenItem.blockchain) {
        case (.transfer(let amount), _):
            let fees = try await feeLoader.getFee(amount: amount, destination: destination)
            return try mapToExpressFee(fees: fees)

        case (.dex(_, _, let txData), .solana):
            guard let txData, let transactionData = Data(base64Encoded: txData) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            let fees = try await feeLoader.asSolanaTokenFeeLoader().getFee(
                compiledTransaction: transactionData
            )

            return try mapToExpressFee(fees: fees)

        case (.dex(_, let txValue, let txData), _):
            guard let txData = txData.map(Data.init(hexString:)) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            let amount = makeAmount(amount: txValue, item: feeTokenItem)
            let fees = try await feeLoader.asEthereumTokenFeeLoader().getFee(
                amount: amount,
                destination: destination,
                txData: txData
            )

            return try mapToExpressFee(fees: fees)
        }
    }
}

// MARK: - Private

private extension CommonExpressFeeLoader {
    func makeAmount(amount: Decimal, item: TokenItem) -> Amount {
        Amount(with: item.blockchain, type: item.amountType, value: amount)
    }

    func mapToExpressFee(fees: [BSDKFee]) throws -> ExpressFee.Variants {
        switch fees.count {
        case 1:
            return .single(fees[0])
        case 3 where tokenItem.blockchain.isUTXO:
            return .single(fees[1])
        case 3:
            return .double(market: fees[1], fast: fees[2])
        default:
            throw ExpressFeeLoaderError.feeNotFound
        }
    }
}
