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

    @Published var disabledReason: DisabledReason?
    @Published var cryptoBalance: LoadableTokenBalanceView.State = .empty
    @Published var fiatBalance: LoadableTokenBalanceView.State = .empty

    let action: () -> Void

    init(
        id: WalletModelId,
        name: String,
        symbol: String,
        tokenIconInfo: TokenIconInfo,
        availabilityProvider: NewTokenSelectorItemAvailabilityProvider,
        cryptoBalanceProvider: TokenBalanceProvider,
        fiatBalanceProvider: TokenBalanceProvider,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.tokenIconInfo = tokenIconInfo
        self.action = action

        availabilityProvider.availabilityTypePublisher
            .map { $0.disabledReason }
            .receiveOnMain()
            .assign(to: &$disabledReason)

        cryptoBalanceProvider.formattedBalanceTypePublisher
            .map { LoadableTokenBalanceViewStateBuilder().build(type: $0) }
            .receiveOnMain()
            .assign(to: &$cryptoBalance)

        fiatBalanceProvider.formattedBalanceTypePublisher
            .map { LoadableTokenBalanceViewStateBuilder().build(type: $0) }
            .receiveOnMain()
            .assign(to: &$fiatBalance)
    }
}

private extension NewTokenSelectorItem.AvailabilityType {
    var disabledReason: NewTokenSelectorItemViewModel.DisabledReason? {
        switch self {
        case .available: .none
        case .unavailable(let reason): reason
        }
    }
}

extension NewTokenSelectorItemViewModel {
    enum DisabledReason {
        case unavailableForSwap
        case unavailableForOnramp
        case unavailableForSell
    }
}
