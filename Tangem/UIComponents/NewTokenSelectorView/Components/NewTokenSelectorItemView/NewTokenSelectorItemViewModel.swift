//
//  NewTokenSelectorItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemUI

final class NewTokenSelectorItemViewModel: ObservableObject, Identifiable {
    let id: WalletModelId
    let name: String
    let symbol: String
    let tokenIconInfo: TokenIconInfo
    let disabledReason: DisabledReason?

    @Published var cryptoBalance: LoadableTokenBalanceView.State = .empty
    @Published var fiatBalance: LoadableTokenBalanceView.State = .empty

    let action: () -> Void

    init(
        id: WalletModelId,
        name: String,
        symbol: String,
        tokenIconInfo: TokenIconInfo,
        disabledReason: DisabledReason?,
        cryptoBalanceProvider: TokenBalanceProvider,
        fiatBalanceProvider: TokenBalanceProvider,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.tokenIconInfo = tokenIconInfo
        self.disabledReason = disabledReason
        self.action = action

        cryptoBalanceProvider.formattedBalanceTypePublisher
            .map { LoadableTokenBalanceViewStateBuilder().build(type: $0) }
            .assign(to: &$cryptoBalance)

        fiatBalanceProvider.formattedBalanceTypePublisher
            .map { LoadableTokenBalanceViewStateBuilder().build(type: $0) }
            .assign(to: &$fiatBalance)
    }
}

extension NewTokenSelectorItemViewModel {
    enum DisabledReason {
        case unavailableForSwap
        case unavailableForOnramp
    }
}
