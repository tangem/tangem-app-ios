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
    func openSwap() {
        guard let parameters = swapParametersFactory.make(depositTargets: interactor.state.depositTargets) else {
            reportUnavailableDeposit()
            return
        }

        coordinator?.openSwapFlow(parameters: parameters)
    }

    func openReceive() {
        let networks = PolymarketDepositNetworkResolver.resolve(depositTargets: interactor.state.depositTargets)

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
