//
//  CommonExpressFeeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import BlockchainSdk
import BigInt

struct CommonExpressFeeProvider {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let feeLoader: any TokenFeeLoader
    private let ethereumNetworkProvider: (any EthereumNetworkProvider)?

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        feeLoader: any TokenFeeLoader,
        ethereumNetworkProvider: (any EthereumNetworkProvider)?
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.feeLoader = feeLoader
        self.ethereumNetworkProvider = ethereumNetworkProvider
    }
}

// MARK: - ExpressFeeProvider

extension CommonExpressFeeProvider: ExpressFeeProvider {
    func estimatedFee(amount: Decimal) async throws -> ExpressFee.Variants {
        let fees = try await feeLoader.estimatedFee(amount: amount)
        return try mapToExpressFee(fees: fees)
    }

    func estimatedFee(estimatedGasLimit: Int) async throws -> Fee {
        guard let ethereumNetworkProvider = ethereumNetworkProvider else {
            throw ExpressFeeProviderError.ethereumNetworkProviderNotFound
        }

        let parameters = try await ethereumNetworkProvider.getFee(
            gasLimit: BigUInt(estimatedGasLimit),
            supportsEIP1559: tokenItem.blockchain.supportsEIP1559
        )

        let amount = parameters.calculateFee(decimalValue: feeTokenItem.decimalValue)
        return Fee(makeAmount(amount: amount, item: tokenItem))
    }

    func getFee(amount: ExpressAmount, destination: String) async throws -> ExpressFee.Variants {
        switch (amount, tokenItem.blockchain) {
        case (.transfer(let amount), _):
            let fees = try await feeLoader.getFee(dataType: .plain(amount: amount, destination: destination))
            return try mapToExpressFee(fees: fees)
        case (.dex(_, _, let txData), .solana):
            guard let txData, let transactionData = Data(base64Encoded: txData) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            let fees = try await feeLoader.getFee(dataType: .compiledTransaction(data: transactionData))
            return try mapToExpressFee(fees: fees)
        case (.dex(_, let txValue, let txData), _):
            guard let txData = txData.map(Data.init(hexString:)) else {
                throw ExpressProviderError.transactionDataNotFound
            }

            // For DEX have to use `txData` when calculate fee
            guard let ethereumNetworkProvider else {
                throw ExpressFeeProviderError.ethereumNetworkProviderNotFound
            }

            let amount = makeAmount(amount: txValue, item: feeTokenItem)
            var fees = try await ethereumNetworkProvider.getFee(
                destination: destination,
                value: amount.encodedForSend,
                data: txData
            ).async()

            // For EVM networks increase gas limit
            fees = fees.map {
                $0.increasingGasLimit(
                    byPercents: EthereumFeeParametersConstants.defaultGasLimitIncreasePercent,
                    blockchain: feeTokenItem.blockchain,
                    decimalValue: feeTokenItem.decimalValue
                )
            }

            return try mapToExpressFee(fees: fees)
        }
    }
}

// MARK: - Private

private extension CommonExpressFeeProvider {
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
            throw ExpressFeeProviderError.feeNotFound
        }
    }
}
