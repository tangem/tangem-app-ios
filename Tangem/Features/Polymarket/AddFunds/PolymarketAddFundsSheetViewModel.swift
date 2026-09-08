//
//  PolymarketAddFundsSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket
import TangemUI
import TangemUIUtils

final class PolymarketAddFundsSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var options: [PolymarketAddFundsSheetOptionView.Option] = [.receive]
    @Published var alert: AlertBinder?

    private let interactor: PolymarketAddFundsInteractor
    private weak var coordinator: PolymarketAddFundsSheetRoutable?

    init(interactor: PolymarketAddFundsInteractor, coordinator: PolymarketAddFundsSheetRoutable) {
        self.interactor = interactor
        self.coordinator = coordinator
    }
}

// MARK: - Actions

extension PolymarketAddFundsSheetViewModel {
    func userDidTapOption(_ option: PolymarketAddFundsSheetOptionView.Option) {
        switch option {
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
    func openReceive() {
        guard let fundingTarget = interactor.state.fundingTarget else {
            PolymarketLogger.warning("Add funds became unavailable while its sheet was open")
            alert = AlertBuilder.makeOkGotItAlert(message: PolymarketAddFundsCopy.unavailableMessage)
            return
        }

        coordinator?.openReceiveSheet(viewModel: makeReceiveViewModel(address: fundingTarget.fundingAddress))
    }

    func makeReceiveViewModel(address: String) -> ReceiveMainViewModel {
        let viewModel = ReceiveMainViewModel(
            options: .init(
                tokenItem: PolymarketUtilities.usdcTokenItem,
                flow: .polymarketDeposit,
                addressTypesProvider: SingleAddressReceiveAddressTypesProvider(
                    address: address,
                    colorScheme: .whiteBlack
                )
            )
        )

        viewModel.start()

        return viewModel
    }
}
