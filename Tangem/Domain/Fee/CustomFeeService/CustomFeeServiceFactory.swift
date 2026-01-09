//
//  CustomFeeProviderBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

enum CustomFeeProviderBuilder {
    static func makeCustomFeeProvider(walletModel: any WalletModel, walletManager: any WalletManager) -> (any CustomFeeProvider)? {
        switch walletModel.tokenItem.blockchain {
        case .bitcoin:
            guard let bitcoinTransactionFeeCalculator = walletManager as? BitcoinTransactionFeeCalculator else {
                return nil
            }

            return BitcoinCustomFeeService(
                tokenItem: walletModel.tokenItem,
                feeTokenItem: walletModel.feeTokenItem,
                bitcoinTransactionFeeCalculator: bitcoinTransactionFeeCalculator
            )

        case .kaspa:
            return KaspaCustomFeeService(tokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)

        case _ where walletModel.tokenItem.blockchain.isEvm:
            return EVMCustomFeeService(sourceTokenItem: walletModel.tokenItem, feeTokenItem: walletModel.feeTokenItem)

        default:
            return nil
        }
    }
}
