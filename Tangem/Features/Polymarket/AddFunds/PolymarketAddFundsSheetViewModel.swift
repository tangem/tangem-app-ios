//
//  PolymarketAddFundsSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemLocalization
import TangemPolymarket
import TangemUI
import TangemUIUtils

final class PolymarketAddFundsSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var options: [PolymarketAddFundsSheetOptionView.Option] = [.swap, .receive]
    @Published var alert: AlertBinder?

    private let interactor: PolymarketAccountFundsInteractor
    private let swapParametersFactory: PolymarketSwapParametersFactory
    private weak var coordinator: PolymarketAddFundsSheetRoutable?

    init(
        interactor: PolymarketAccountFundsInteractor,
        swapParametersFactory: PolymarketSwapParametersFactory,
        coordinator: PolymarketAddFundsSheetRoutable
    ) {
        self.interactor = interactor
        self.swapParametersFactory = swapParametersFactory
        self.coordinator = coordinator
    }
}

// MARK: - Actions

extension PolymarketAddFundsSheetViewModel {
    func userDidTapOption(_ option: PolymarketAddFundsSheetOptionView.Option) {
        switch option {
        case .swap:
            openSwap()

        case .receive:
            openReceive()
        }
    }

    func close() {
        coordinator?.closeAddFundsSheet()
    }
}

// MARK: - Private implementation

private extension PolymarketAddFundsSheetViewModel {
    var availableDepositTargets: [PolymarketAccountFundsInteractor.DepositTarget]? {
        switch interactor.state {
        case .ready(let readiness):
            switch readiness.depositAvailability {
            case .available(let depositTargets):
                depositTargets
            case .unavailable:
                nil
            }
        case .loading, .unavailable:
            nil
        }
    }

    func openSwap() {
        guard
            let depositTargets = availableDepositTargets,
            let parameters = swapParametersFactory.make(depositTargets: depositTargets)
        else {
            reportUnavailableDeposit()
            return
        }

        coordinator?.openSwapFlow(parameters: parameters)
    }

    func openReceive() {
        guard let depositTargets = availableDepositTargets else {
            reportUnavailableDeposit()
            return
        }

        let networks = PolymarketDepositNetworkResolver.resolve(depositTargets: depositTargets)

        guard networks.isNotEmpty else {
            reportUnavailableDeposit()
            return
        }

        coordinator?.openChooseNetworkSheet(networks: networks)
    }

    func reportUnavailableDeposit() {
        PolymarketLogger.warning("Add funds became unavailable while its sheet was open")
        alert = AlertBuilder.makeOkGotItAlert(message: Localization.predictionAddFundsErrorDescription)
    }
}
