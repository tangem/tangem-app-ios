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
    private let feeProvider: any WalletModelFeeProvider
    private let ethereumNetworkProvider: (any EthereumNetworkProvider)?

    init(
        tokenItem: TokenItem,
        feeTokenItem: TokenItem,
        feeProvider: any WalletModelFeeProvider,
        ethereumNetworkProvider: (any EthereumNetworkProvider)?
    ) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.feeProvider = feeProvider
        self.ethereumNetworkProvider = ethereumNetworkProvider
    }
}

// MARK: - ExpressFeeProvider

extension CommonExpressFeeProvider: ExpressFeeProvider {
    func estimatedFee(amount: Decimal) async throws -> ExpressFee.Variants {
        let amount = makeAmount(amount: amount, item: tokenItem)
        let fees = try await feeProvider.estimatedFee(amount: amount).async()
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
        switch amount {
        case .transfer(let amount):
            let amount = makeAmount(amount: amount, item: tokenItem)
            let fees = try await feeProvider.getFee(amount: amount, destination: destination).async()
            return try mapToExpressFee(fees: fees)

        case .dex(let txValue, let txData):
            // For DEX have to use `txData` when calculate fee
            guard let ethereumNetworkProvider = ethereumNetworkProvider else {
                throw ExpressFeeProviderError.ethereumNetworkProviderNotFound
            }

            let amount = makeAmount(amount: txValue, item: feeTokenItem)
            var fees = try await ethereumNetworkProvider.getFee(
                destination: destination,
                value: amount.encodedForSend,
                data: txData
            ).async()

            // For EVM networks increase gas limit
            fees = fees.map { increaseGasLimit(fee: $0) }

            return try mapToExpressFee(fees: fees)
        }
    }
}

// MARK: - Private

private extension CommonExpressFeeProvider {
    func makeAmount(amount: Decimal, item: TokenItem) -> Amount {
        Amount(with: item.blockchain, type: item.amountType, value: amount)
    }

    func mapToExpressFee(fees: [Fee]) throws -> ExpressFee.Variants {
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

    func increaseGasLimit(fee: Fee) -> Fee {
        guard let parameters = fee.parameters as? EthereumFeeParameters else {
            return fee
        }

        let gasLimit = parameters.gasLimit * BigUInt(112) / BigUInt(100)
        let newParameters = parameters.changingGasLimit(to: gasLimit)
        let feeValue = newParameters.calculateFee(decimalValue: feeTokenItem.decimalValue)
        let amount = Amount(with: feeTokenItem.blockchain, type: feeTokenItem.amountType, value: feeValue)
        return Fee(amount, parameters: newParameters)
    }
}

enum ExpressFeeProviderError: Error {
    case feeNotFound
    case ethereumNetworkProviderNotFound
}
