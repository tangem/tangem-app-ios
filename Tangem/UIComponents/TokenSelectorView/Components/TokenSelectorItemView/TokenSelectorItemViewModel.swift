//
//  TokenSelectorItemViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemLocalization
import TangemUI

final class TokenSelectorItemViewModel: ObservableObject, Identifiable {
    let id: WalletModelId
    let name: String
    let symbol: String
    let tokenIconInfo: TokenIconInfo

    @Published var availabilityType: TokenSelectorItem.AvailabilityType = .available
    @Published var cryptoBalance: LoadableBalanceView.State
    @Published var fiatBalance: LoadableBalanceView.State

    let action: (TokenSelectorItem.AvailabilityType) -> Void

    var secondaryLeadingText: String {
        switch availabilityType {
        case .available, .unavailable(.unavailableForSend):
            symbol
        case .unavailable(.unavailableForOnramp):
            Localization.tokensListUnavailableToPurchaseHeader
        case .unavailable(.unavailableForSwap(.sourceState(.jointAccountsComingSoon))),
             .unavailable(.unavailableForSell(.jointAccountsComingSoon)):
            Localization.commonComingSoon
        case .unavailable(.unavailableForSwap):
            Localization.tokensListUnavailableToSwapSourceHeader
        case .unavailable(.unavailableForSell):
            Localization.tokensListUnavailableToSellHeader
        }
    }

    init(
        id: WalletModelId,
        name: String,
        symbol: String,
        tokenIconInfo: TokenIconInfo,
        availabilityTypePublisher: AnyPublisher<TokenSelectorItem.AvailabilityType, Never>,
        cryptoBalanceProvider: TokenBalanceProvider,
        fiatBalanceProvider: TokenBalanceProvider,
        action: @escaping (TokenSelectorItem.AvailabilityType) -> Void
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
            .receiveOnMain()
            .assign(to: &$availabilityType)
    }
}

extension TokenSelectorItem.AvailabilityType {
    var disablesTap: Bool {
        switch self {
        case .available: false
        case .unavailable(.unavailableForSwap(.noAddress)): true
        case .unavailable(.unavailableForSwap(.sourceState(.customToken))): true
        case .unavailable(.unavailableForSwap(.receiveState(.customToken))): true
        case .unavailable(.unavailableForSwap(.sourceState)), .unavailable(.unavailableForSwap(.receiveState)): false
        case .unavailable(.unavailableForSell(.jointAccountsComingSoon)): false
        case .unavailable(.unavailableForOnramp), .unavailable(.unavailableForSell), .unavailable(.unavailableForSend): true
        }
    }
}

extension TokenSelectorItemViewModel {
    enum DisabledReason {
        case unavailableForSwap(SwapUnavailabilityReason)
        case unavailableForOnramp
        case unavailableForSell(TokenActionAvailabilityProvider.SellActionAvailabilityStatus)
        case unavailableForSend
    }

    enum SwapUnavailabilityReason {
        case noAddress
        case sourceState(TokenActionAvailabilityProvider.SwapSourceActionAvailabilityStatus)
        case receiveState(TokenActionAvailabilityProvider.SwapReceiveActionAvailabilityStatus)
    }
}
