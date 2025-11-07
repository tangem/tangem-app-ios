//
//  TangemPayDestinationWalletWrapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress

protocol ExpressInteractorTangemPayDestinationWallet: ExpressInteractorDestinationWallet {
    /// Better update to `var balanceProvider: TokenBalanceProvider { get }`
    /// When it will be needed
    var balancePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never> { get }
}

struct TangemPayDestinationWalletWrapper: ExpressInteractorTangemPayDestinationWallet {
    let id: WalletModelId
    let tokenItem: TokenItem
    let isCustom: Bool = false
    let balancePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never>

    var currency: ExpressWalletCurrency { tokenItem.expressCurrency }
    let address: String?

    init(tokenItem: TokenItem, address: String, balancePublisher: AnyPublisher<LoadableTokenBalanceView.State, Never>) {
        id = .init(tokenItem: tokenItem)
        self.tokenItem = tokenItem
        self.address = address
        self.balancePublisher = balancePublisher
    }
}
