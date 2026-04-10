//
//  TokenSelectorItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemUI

final class TokenSelectorItemViewModel: ObservableObject, Identifiable {
    let id: WalletModelId
    let name: String
    let symbol: String
    let tokenIconInfo: TokenIconInfo

    @Published var disabledReason: DisabledReason?
    @Published var cryptoBalance: LoadableBalanceView.State
    @Published var fiatBalance: LoadableBalanceView.State

    let action: () -> Void

    init(
        id: WalletModelId,
        name: String,
        symbol: String,
        tokenIconInfo: TokenIconInfo,
        availabilityTypePublisher: AnyPublisher<TokenSelectorItem.AvailabilityType, Never>,
        cryptoBalanceProvider: TokenBalanceProvider,
        fiatBalanceProvider: TokenBalanceProvider,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.tokenIconInfo = tokenIconInfo
        self.action = action

        cryptoBalance = LoadableBalanceViewStateBuilder().build(type: cryptoBalanceProvider.formattedBalanceType)
        fiatBalance = LoadableBalanceViewStateBuilder().build(type: fiatBalanceProvider.formattedBalanceType)

        cryptoBalanceProvider.formattedBalanceTypePublisher
            .map { LoadableBalanceViewStateBuilder().build(type: $0) }
            .receiveOnMain()
            .assign(to: &$cryptoBalance)

        fiatBalanceProvider.formattedBalanceTypePublisher
            .map { LoadableBalanceViewStateBuilder().build(type: $0) }
            .receiveOnMain()
            .assign(to: &$fiatBalance)

        availabilityTypePublisher
            .map { $0.disabledReason }
            .receiveOnMain()
            .assign(to: &$disabledReason)
    }
}

private extension TokenSelectorItem.AvailabilityType {
    var disabledReason: TokenSelectorItemViewModel.DisabledReason? {
        switch self {
        case .available: .none
        case .unavailable(let reason): reason
        }
    }
}

extension TokenSelectorItemViewModel {
    enum DisabledReason {
        case unavailableForSwap
        case unavailableForOnramp
        case unavailableForSell
        case unavailableForSend
    }
}
