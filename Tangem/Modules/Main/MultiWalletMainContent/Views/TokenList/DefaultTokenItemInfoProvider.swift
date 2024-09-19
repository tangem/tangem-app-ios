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

    init(walletModel: WalletModel) {
        self.walletModel = walletModel
    }
}

extension DefaultTokenItemInfoProvider: TokenItemInfoProvider {
    var id: Int { walletModel.id }

    var tokenItemState: TokenItemViewState {
        TokenItemViewState(walletModelState: walletModel.state)
    }

    var tokenItemStatePublisher: AnyPublisher<TokenItemViewState, Never> {
        walletModel.walletDidChangePublisher
            .map(TokenItemViewState.init)
            .eraseToAnyPublisher()
    }

    var tokenItem: TokenItem { walletModel.tokenItem }

    var hasPendingTransactions: Bool { walletModel.hasPendingTransactions }

    var balance: String { walletModel.allBalanceFormatted.crypto }

    var isZeroBalanceValue: Bool { walletModel.allBalance.crypto?.isZero ?? true }

    var fiatBalance: String { walletModel.allBalanceFormatted.fiat }

    var quote: TokenQuote? { walletModel.quote }

    var actionsUpdatePublisher: AnyPublisher<Void, Never> { walletModel.actionsUpdatePublisher }

    var isStakedPublisher: AnyPublisher<Bool, Never> {
        walletModel.stakingManagerStatePublisher
            .filter { $0 != .loading }
            .map { state in
                switch state {
                case .staked: true
                case .loading, .availableToStake, .notEnabled, .temporaryUnavailable, .loadingError: false
                }
            }
            .eraseToAnyPublisher()
    }
}
