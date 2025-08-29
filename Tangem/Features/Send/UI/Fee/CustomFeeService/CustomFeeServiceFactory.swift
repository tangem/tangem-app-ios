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

    func makeService(input: CustomFeeServiceInput) -> CustomFeeService? {
        let blockchain = walletModel.tokenItem.blockchain

        if case .bitcoin = blockchain,
           let bitcoinTransactionFeeCalculator = walletModel.bitcoinTransactionFeeCalculator {
            if FeatureProvider.isAvailable(.sendViaSwap) {
                return NewCustomBitcoinFeeService(
                    input: input,
                    tokenItem: walletModel.tokenItem,
                    feeTokenItem: walletModel.feeTokenItem,
                    bitcoinTransactionFeeCalculator: bitcoinTransactionFeeCalculator
                )
            }

            return CustomBitcoinFeeService(
                input: input,
                tokenItem: walletModel.tokenItem,
                feeTokenItem: walletModel.feeTokenItem,
                bitcoinTransactionFeeCalculator: bitcoinTransactionFeeCalculator
            )
        }

        if case .kaspa = blockchain {
            if FeatureProvider.isAvailable(.sendViaSwap) {
                return NewCustomKaspaFeeService(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)
            }

            return CustomKaspaFeeService(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)
        }

        if blockchain.isEvm {
            if FeatureProvider.isAvailable(.sendViaSwap) {
                return NewCustomEvmFeeService(sourceTokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)
            }

            return CustomEvmFeeService(sourceTokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)
        }

        return nil
    }
}
