//
//  SendFeeLoader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk

protocol SendFeeLoader {
    func getFee(amount: Decimal, destination: String) -> AnyPublisher<[Fee], Error>
}

struct CommonSendFeeLoader: SendFeeLoader {
    private let tokenItem: TokenItem
    private let walletModelFeeProvider: any WalletModelFeeProvider
    private let shouldShowFeeSelector: Bool

    init(tokenItem: TokenItem, walletModelFeeProvider: any WalletModelFeeProvider, shouldShowFeeSelector: Bool) {
        self.tokenItem = tokenItem
        self.walletModelFeeProvider = walletModelFeeProvider
        self.shouldShowFeeSelector = shouldShowFeeSelector
    }

    func getFee(amount: Decimal, destination: String) -> AnyPublisher<[Fee], any Error> {
        let amount = Amount(with: tokenItem.blockchain, type: tokenItem.amountType, value: amount)
        return walletModelFeeProvider.getFee(amount: amount, destination: destination)
    }
}
