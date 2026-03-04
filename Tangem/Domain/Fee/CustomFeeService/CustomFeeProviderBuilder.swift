//
//  CustomFeeProviderBuilder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CustomFeeProviderBuilder {
    let tokenItem: TokenItem
    let feeTokenItem: TokenItem
    let walletManager: any WalletManager

    func makeCustomFeeProvider() -> (any CustomFeeProvider)? {
        switch tokenItem.blockchain {
        case .bitcoin:
            guard let bitcoinTransactionFeeCalculator = walletManager as? BitcoinTransactionFeeCalculator else {
                return nil
            }

            return BitcoinCustomFeeService(
                tokenItem: tokenItem,
                feeTokenItem: feeTokenItem,
                bitcoinTransactionFeeCalculator: bitcoinTransactionFeeCalculator
            )

        case .kaspa:
            return KaspaCustomFeeService(tokenItem: tokenItem, feeTokenItem: feeTokenItem)

        case _ where tokenItem.blockchain.isEvm:
            return EVMCustomFeeService(sourceTokenItem: tokenItem, feeTokenItem: feeTokenItem)

        default:
            return nil
        }
    }
}
