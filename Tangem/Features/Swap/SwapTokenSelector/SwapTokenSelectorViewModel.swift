//
//  SwapTokenSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemExpress
import TangemLocalization
import TangemFoundation

final class SwapTokenSelectorViewModel: ObservableObject, Identifiable {
    // MARK: - View

    let tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel

    // MARK: - Dependencies

    private let swapDirection: SwapDirection
    private let expressInteractor: ExpressInteractor
    private weak var coordinator: SwapTokenSelectorRoutable?

    private var selectedTokenItem: TokenItem?

    init(
        swapDirection: SwapDirection,
        tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel,
        expressInteractor: ExpressInteractor,
        coordinator: SwapTokenSelectorRoutable
    ) {
        self.swapDirection = swapDirection
        self.tokenSelectorViewModel = tokenSelectorViewModel
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator

        tokenSelectorViewModel.setup(directionPublisher: Just(swapDirection).eraseToOptional())
        tokenSelectorViewModel.setup(with: self)
    }

    func close() {
        coordinator?.closeSwapTokenSelector()
    }

    func onDisappear() {
        if let tokenItem = selectedTokenItem {
            Analytics.log(
                event: .swapChooseTokenScreenResult,
                params: [
                    .tokenChosen: Analytics.ParameterValue.yes.rawValue,
                    .token: tokenItem.currencySymbol,
                ]
            )
        } else {
            Analytics.log(
                event: .swapChooseTokenScreenResult,
                params: [.tokenChosen: Analytics.ParameterValue.no.rawValue]
            )
        }
    }
}

// MARK: - AccountsAwareTokenSelectorViewModelOutput

extension SwapTokenSelectorViewModel: AccountsAwareTokenSelectorViewModelOutput {
    func usedDidSelect(item: AccountsAwareTokenSelectorItem) {
        let expressInteractorWallet = ExpressInteractorWalletModelWrapper(
            userWalletInfo: item.userWalletInfo,
            walletModel: item.walletModel,
            expressOperationType: .swap
        )

        switch swapDirection {
        case .fromSource:
            expressInteractor.update(destination: expressInteractorWallet)
        case .toDestination:
            expressInteractor.update(sender: expressInteractorWallet)
        }

        selectedTokenItem = item.walletModel.tokenItem
        coordinator?.closeSwapTokenSelector()
    }
}

extension SwapTokenSelectorViewModel {
    typealias SwapDirection = AccountsAwareTokenSelectorItemSwapAvailabilityProvider.SwapDirection
}

extension SwapTokenSelectorViewModel.SwapDirection {
    var tokenItem: TokenItem {
        switch self {
        case .fromSource(let tokenItem): tokenItem
        case .toDestination(let tokenItem): tokenItem
        }
    }
}
