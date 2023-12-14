//
//  CommonExpressFeeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping
import BlockchainSdk

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

    func getFee(amount: Decimal, destination: String, hexData: Data?) async throws -> ExpressFee {
        let amount = makeAmount(amount: amount)

        // If EVM network we should pass data in the fee calculation
        if let ethereumNetworkProvider = wallet.ethereumNetworkProvider, let hexData {
            let fees = try await ethereumNetworkProvider.getFee(
                destination: destination,
                value: amount.encodedForSend,
                data: hexData
            ).async()

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
}

enum ExpressFeeProviderError: Error {
    case feeNotFound
}
