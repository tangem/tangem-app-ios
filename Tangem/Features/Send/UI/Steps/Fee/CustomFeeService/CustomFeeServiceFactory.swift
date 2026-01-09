//
//  CustomFeeServiceFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct CustomFeeServiceFactory {
    private let tokenItem: TokenItem
    private let feeTokenItem: TokenItem
    private let bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator?

    init(tokenItem: TokenItem, feeTokenItem: TokenItem, bitcoinTransactionFeeCalculator: BitcoinTransactionFeeCalculator?) {
        self.tokenItem = tokenItem
        self.feeTokenItem = feeTokenItem
        self.bitcoinTransactionFeeCalculator = bitcoinTransactionFeeCalculator
    }

    func makeService() -> FeeSelectorCustomFeeProvider? {
        switch tokenItem.blockchain {
        case .bitcoin where bitcoinTransactionFeeCalculator != nil:
            return BitcoinCustomFeeService(
                tokenItem: tokenItem,
                feeTokenItem: feeTokenItem,
                bitcoinTransactionFeeCalculator: bitcoinTransactionFeeCalculator!
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
