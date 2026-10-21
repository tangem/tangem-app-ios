//
//  WalletModelSendingRestrictionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

struct WalletModelSendingRestrictionsProvider: SendingRestrictionsProvider {
    let walletModel: any WalletModel

    var sendingRestrictionsPublisher: AnyPublisher<SendingRestrictions?, Never> {
        walletModel.availableBalanceProvider.balanceTypePublisher
            .map { [walletModel] _ in walletModel.sendingRestrictions }
            .eraseToAnyPublisher()
    }
}
