//
//  PolymarketAddFundsSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import TangemPolymarket
import TangemUI
import TangemUIUtils

final class PolymarketAddFundsSheetViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Published private(set) var options: [PolymarketAddFundsSheetOptionView.Option] = [.swap, .receive]
    @Published var alert: AlertBinder?

    private let interactor: PolymarketAddFundsInteractor
    private let swapParametersFactory: PolymarketSwapParametersFactory
    private weak var coordinator: PolymarketAddFundsSheetRoutable?

    init(
        interactor: PolymarketAddFundsInteractor,
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
        guard let fundingTarget = interactor.state.fundingTarget else {
            PolymarketLogger.warning("Add funds became unavailable while its sheet was open")
            alert = AlertBuilder.makeOkGotItAlert(message: Localization.predictionAddFundsErrorDescription)
            return
        }

        let parameters = swapParametersFactory.make(fundingTarget: fundingTarget)
        coordinator?.openSwapFlow(parameters: parameters)
    }

    func openReceive() {
        guard let fundingTarget = interactor.state.fundingTarget else {
            PolymarketLogger.warning("Add funds became unavailable while its sheet was open")
            alert = AlertBuilder.makeOkGotItAlert(message: Localization.predictionAddFundsErrorDescription)
            return
        }

        coordinator?.openReceiveSheet(viewModel: makeReceiveViewModel(fundingTarget: fundingTarget))
    }

    func minimumDepositFormatted(for asset: PolymarketSupportedAsset) -> String {
        BalanceFormatter().formatFiatBalance(asset.minimumDepositUSD, currencyCode: AppConstants.usdCurrencyCode)
    }

    func makeReceiveViewModel(fundingTarget: PolymarketAddFundsInteractor.FundingTarget) -> ReceiveMainViewModel {
        let viewModel = ReceiveMainViewModel(
            options: .init(
                tokenItem: PolymarketUtilities.usdcTokenItem,
                flow: .polymarketDeposit(minimumDepositFormatted: minimumDepositFormatted(for: fundingTarget.asset)),
                addressTypesProvider: SingleAddressReceiveAddressTypesProvider(
                    address: fundingTarget.fundingAddress,
                    colorScheme: .whiteBlack
                )
            )
        )

        viewModel.start()

        return viewModel
    }
}
