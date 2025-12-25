//
//  AccountsAwareTokenSelectorItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemUI

final class AccountsAwareTokenSelectorItemViewModel: ObservableObject, Identifiable {
    let id: WalletModelId
    let name: String
    let symbol: String
    let tokenIconInfo: TokenIconInfo

    @Published var disabledReason: DisabledReason?
    @Published var cryptoBalance: LoadableTokenBalanceView.State
    @Published var fiatBalance: LoadableTokenBalanceView.State

    let action: () -> Void

    init(
        id: WalletModelId,
        name: String,
        symbol: String,
        tokenIconInfo: TokenIconInfo,
        availabilityTypePublisher: AnyPublisher<AccountsAwareTokenSelectorItem.AvailabilityType, Never>,
        cryptoBalanceProvider: TokenBalanceProvider,
        fiatBalanceProvider: TokenBalanceProvider,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.tokenIconInfo = tokenIconInfo
        self.action = action

        cryptoBalance = LoadableTokenBalanceViewStateBuilder().build(type: cryptoBalanceProvider.formattedBalanceType)
        fiatBalance = LoadableTokenBalanceViewStateBuilder().build(type: fiatBalanceProvider.formattedBalanceType)

        cryptoBalanceProvider.formattedBalanceTypePublisher
            .map { LoadableTokenBalanceViewStateBuilder().build(type: $0) }
            .receiveOnMain()
            .assign(to: &$cryptoBalance)

        fiatBalanceProvider.formattedBalanceTypePublisher
            .map { LoadableTokenBalanceViewStateBuilder().build(type: $0) }
            .receiveOnMain()
            .assign(to: &$fiatBalance)

        availabilityTypePublisher
            .map { $0.disabledReason }
            .receiveOnMain()
            .assign(to: &$disabledReason)
    }
}

private extension AccountsAwareTokenSelectorItem.AvailabilityType {
    var disabledReason: AccountsAwareTokenSelectorItemViewModel.DisabledReason? {
        switch self {
        case .available: .none
        case .unavailable(let reason): reason
        }
    }
}

extension AccountsAwareTokenSelectorItemViewModel {
    enum DisabledReason {
        case unavailableForSwap
        case unavailableForOnramp
        case unavailableForSell
    }
}
