//
//  CustomFeeServiceFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct CustomFeeServiceFactory {
    private let walletModel: any WalletModel

    init(walletModel: any WalletModel) {
        self.walletModel = walletModel
    }

    func makeService() -> CustomFeeService? {
        let blockchain = walletModel.tokenItem.blockchain

        if case .bitcoin = blockchain,
           let bitcoinTransactionFeeCalculator = walletModel.bitcoinTransactionFeeCalculator {
            return CustomBitcoinFeeService(
                tokenItem: walletModel.tokenItem,
                feeTokenItem: walletModel.feeTokenItem,
                bitcoinTransactionFeeCalculator: bitcoinTransactionFeeCalculator
            )
        }

        if case .kaspa = blockchain {
            return CustomKaspaFeeService(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)
        }

        if blockchain.isEvm {
            return CustomEvmFeeService(feeTokenItem: walletModel.feeTokenItem)
        }

        return nil
    }
}
