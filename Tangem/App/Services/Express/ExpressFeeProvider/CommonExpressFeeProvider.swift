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

class CommonExpressFeeProvider {
    var wallet: WalletModel

    init(wallet: WalletModel) {
        self.wallet = wallet
    }
}

// MARK: - ExpressFeeProvider

extension CommonExpressFeeProvider: ExpressFeeProvider {
    func setup(wallet: WalletModel) {
        self.wallet = wallet
    }

    func estimatedFee(amount: Decimal) async throws -> ExpressFee {
        let amount = makeAmount(amount: amount)
        let fees = try await wallet.estimatedFee(amount: amount).async()
        return try mapToExpressFee(fees: fees)
    }

    func estimatedFee(estimatedGasLimit: Int) async throws -> Fee {
        guard let ethereumNetworkProvider = wallet.ethereumNetworkProvider else {
            throw ExpressFeeProviderError.ethereumNetworkProviderNotFound
        }

        let parameters = try await ethereumNetworkProvider.getFee(
            gasLimit: BigUInt(estimatedGasLimit),
            supportsEIP1559: wallet.tokenItem.blockchain.supportsEIP1559
        )

        let amount = parameters.calculateFee(decimalValue: wallet.feeTokenItem.decimalValue)
        return Fee(makeAmount(amount: amount))
    }

    func getFee(amount: Decimal, destination: String, hexData: Data?) async throws -> ExpressFee {
        let amount = makeAmount(amount: amount)

        // If EVM network we should pass data in the fee calculation
        if let ethereumNetworkProvider = wallet.ethereumNetworkProvider, let hexData {
            var fees = try await ethereumNetworkProvider.getFee(
                destination: destination,
                value: amount.encodedForSend,
                data: hexData
            ).async()

            // For EVM networks increase gas limit
            fees = fees.map { increaseGasLimit(fee: $0) }

            return try mapToExpressFee(fees: fees)
        }

        let fees = try await wallet.getFee(amount: amount, destination: destination).async()
        return try mapToExpressFee(fees: fees)
    }
}

// MARK: - Private

private extension CommonExpressFeeProvider {
    func makeAmount(amount: Decimal) -> Amount {
        Amount(
            with: wallet.blockchainNetwork.blockchain,
            type: wallet.amountType,
            value: amount
        )
    }

    func mapToExpressFee(fees: [Fee]) throws -> ExpressFee {
        switch fees.count {
        case 1:
            return .single(fees[0])
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
        let feeValue = newParameters.calculateFee(decimalValue: wallet.feeTokenItem.decimalValue)
        let amount = Amount(with: wallet.feeTokenItem.blockchain, type: wallet.feeTokenItem.amountType, value: feeValue)
        return Fee(amount, parameters: newParameters)
    }
}

enum ExpressFeeProviderError: Error {
    case feeNotFound
    case ethereumNetworkProviderNotFound
}
