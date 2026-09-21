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
        guard let depositTarget = interactor.state.depositTarget else {
            PolymarketLogger.warning("Add funds became unavailable while its sheet was open")
            alert = AlertBuilder.makeOkGotItAlert(message: Localization.predictionAddFundsErrorDescription)
            return
        }

        let parameters = swapParametersFactory.make(depositTarget: depositTarget)
        coordinator?.openSwapFlow(parameters: parameters)
    }

    func openReceive() {
        guard let depositTarget = interactor.state.depositTarget else {
            PolymarketLogger.warning("Add funds became unavailable while its sheet was open")
            alert = AlertBuilder.makeOkGotItAlert(message: Localization.predictionAddFundsErrorDescription)
            return
        }

        coordinator?.openReceiveSheet(viewModel: makeReceiveViewModel(depositTarget: depositTarget))
    }

    func minimumDepositFormatted(for asset: PolymarketSupportedAsset) -> String {
        BalanceFormatter().formatFiatBalance(asset.minCheckoutUSD, currencyCode: AppConstants.usdCurrencyCode)
    }

    func makeReceiveViewModel(depositTarget: PolymarketAccountFundsInteractor.DepositTarget) -> ReceiveMainViewModel {
        let viewModel = ReceiveMainViewModel(
            options: .init(
                tokenItem: PolymarketUtilities.usdcTokenItem,
                flow: .polymarketDeposit(minimumDepositFormatted: minimumDepositFormatted(for: depositTarget.asset)),
                addressTypesProvider: SingleAddressReceiveAddressTypesProvider(
                    address: depositTarget.fundingAddress,
                    colorScheme: .whiteBlack
                )
            ),
            receiveTokenWithdrawNoticeInteractor: PolymarketReceiveTokenWithdrawNoticeInteractor()
        )

        viewModel.start()

        return viewModel
    }
}
