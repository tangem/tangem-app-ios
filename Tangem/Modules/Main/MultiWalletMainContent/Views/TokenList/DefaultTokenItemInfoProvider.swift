//
//  DefaultTokenItemInfoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class DefaultTokenItemInfoProvider {
    private let walletModel: WalletModel

    private let stakingBalanceProvider: TokenBalanceProvider
    private let balanceProvider: TokenBalanceProvider
    private let fiatBalanceProvider: TokenBalanceProvider

    init(walletModel: WalletModel) {
        self.walletModel = walletModel

        stakingBalanceProvider = walletModel.stakingBalanceProvider
        balanceProvider = walletModel.totalTokenBalanceProvider
        fiatBalanceProvider = walletModel.fiatTotalTokenBalanceProvider
    }
}

extension DefaultTokenItemInfoProvider: TokenItemInfoProvider {
    var id: WalletModel.ID { walletModel.id }

    var tokenItem: TokenItem { walletModel.tokenItem }

    var hasPendingTransactions: Bool { walletModel.hasPendingTransactions }

    var quote: WalletModel.Rate {
        walletModel.rate
    }

    var balance: TokenBalanceType {
        balanceProvider.balanceType
    }

    var balanceType: FormattedTokenBalanceType {
        balanceProvider.formattedBalanceType
    }

    var fiatBalanceType: FormattedTokenBalanceType {
        fiatBalanceProvider.formattedBalanceType
    }

    var quotePublisher: AnyPublisher<WalletModel.Rate, Never> {
        walletModel.ratePublisher.eraseToAnyPublisher()
    }

    var balancePublisher: AnyPublisher<TokenBalanceType, Never> {
        balanceProvider.balanceTypePublisher
    }

    var balanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        balanceProvider.formattedBalanceTypePublisher
    }

    var fiatBalanceTypePublisher: AnyPublisher<FormattedTokenBalanceType, Never> {
        fiatBalanceProvider.formattedBalanceTypePublisher
    }

    var actionsUpdatePublisher: AnyPublisher<Void, Never> { walletModel.actionsUpdatePublisher }

    var isStakedPublisher: AnyPublisher<Bool, Never> {
        stakingBalanceProvider
            .balanceTypePublisher
            .map { ($0.value ?? 0) > 0 }
            .eraseToAnyPublisher()
    }
}

extension DefaultTokenItemInfoProvider: Equatable {
    static func == (lhs: DefaultTokenItemInfoProvider, rhs: DefaultTokenItemInfoProvider) -> Bool {
        lhs.id == rhs.id
    }
}
