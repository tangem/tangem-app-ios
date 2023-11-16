//
//  WalletModel+ExpressWallet.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSwapping
import BlockchainSdk

extension TokenItem {
    var expressCurrency: TangemSwapping.ExpressCurrency {
        switch self {
        case .blockchain(let blockchain):
            return TangemSwapping.ExpressCurrency(
                // Fixed constant value for the main token contract address
                contractAddress: ExpressConstants.coinContractAddress,
                network: blockchain.networkId
            )
        case .token(let token, let blockchain):
            return TangemSwapping.ExpressCurrency(
                contractAddress: token.contractAddress,
                network: blockchain.networkId
            )
        }
    }
}

extension WalletModel: ExpressWallet {
    var currency: TangemSwapping.ExpressCurrency {
        tokenItem.expressCurrency
    }

    var address: String { defaultAddress }

    var decimalCount: Int {
        tokenItem.decimalCount
    }

    func getBalance() async throws -> Decimal {
        if let balanceValue {
            return balanceValue
        }

        _ = await update(silent: true).async()

        if let balanceValue {
            return balanceValue
        }

        throw ExpressManagerError.amountNotFound
    }

    func getCoinBalance() async throws -> Decimal {
        if let coinBalance = getDecimalBalance(for: .coin) {
            return coinBalance
        }

        _ = await update(silent: true).async()

        if let coinBalance = getDecimalBalance(for: .coin) {
            return coinBalance
        }

        throw ExpressManagerError.amountNotFound
    }
}
