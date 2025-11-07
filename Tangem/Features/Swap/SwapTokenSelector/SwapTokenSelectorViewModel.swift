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

    lazy var tokenSelectorViewModel = NewTokenSelectorViewModel(
        walletsProvider: walletsProvider,
        output: self
    )

    // MARK: - Private

    private lazy var walletsProvider = SwapNewTokenSelectorWalletsProvider(
        selectedItem: .just(output: swapDirection.tokenItem),
        availabilityProviderFactory: NewTokenSelectorItemSwapAvailabilityProviderFactory(
            directionPublisher: .just(output: swapDirection)
        )
    )

    // MARK: - Dependencies

    private let swapDirection: SwapDirection
    private let expressPairsRepository: ExpressPairsRepository
    private let expressInteractor: ExpressInteractor
    private weak var coordinator: SwapTokenSelectorRoutable?

    private var selectedTokenItem: TokenItem?

    init(
        swapDirection: SwapDirection,
        expressPairsRepository: ExpressPairsRepository,
        expressInteractor: ExpressInteractor,
        coordinator: SwapTokenSelectorRoutable
    ) {
        self.swapDirection = swapDirection
        self.expressPairsRepository = expressPairsRepository
        self.expressInteractor = expressInteractor
        self.coordinator = coordinator
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

// MARK: - NewTokenSelectorViewModelOutput

extension SwapTokenSelectorViewModel: NewTokenSelectorViewModelOutput {
    func usedDidSelect(item: NewTokenSelectorItem) {
        switch swapDirection {
        case .fromSource:
            expressInteractor.update(destination: item.walletModel.asExpressInteractorWallet)
        case .toDestination:
            expressInteractor.update(sender: item.walletModel.asExpressInteractorWallet)
        }

        selectedTokenItem = item.walletModel.tokenItem
        coordinator?.closeSwapTokenSelector()
    }
}

extension SwapTokenSelectorViewModel {
    typealias SwapDirection = NewTokenSelectorItemSwapAvailabilityProviderFactory.SwapDirection
}

extension SwapTokenSelectorViewModel.SwapDirection {
    var tokenItem: TokenItem {
        switch self {
        case .fromSource(let tokenItem): tokenItem
        case .toDestination(let tokenItem): tokenItem
        }
    }
}
