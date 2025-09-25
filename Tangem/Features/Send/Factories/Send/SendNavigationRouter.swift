//
//  SendNavigationRouter.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

class SendNavigationRouter {
    let stepsManager: any SendStepsManager
    let sendBaseDataBuilder: any SendBaseDataBuilder
    let feeSelector: FeeSelectorContentViewModel
    let providersSelector: SendSwapProvidersSelectorViewModel
    weak var router: (any SendRoutable)?

    init(
        stepsManager: any SendStepsManager,
        sendBaseDataBuilder: any SendBaseDataBuilder,
        feeSelector: FeeSelectorContentViewModel,
        providersSelector: SendSwapProvidersSelectorViewModel,
        router: any SendRoutable
    ) {
        self.stepsManager = stepsManager
        self.sendBaseDataBuilder = sendBaseDataBuilder
        self.feeSelector = feeSelector
        self.providersSelector = providersSelector
        self.router = router
    }

    deinit {
        print("deinit SendNavigationRouter")
    }
}

extension SendNavigationRouter: SendSummaryStepsRoutable {
    func summaryStepRequestEditDestination() {
        (stepsManager as? SendSummaryStepsRoutable)?.summaryStepRequestEditDestination()
    }

    func summaryStepRequestEditAmount() {
        (stepsManager as? SendSummaryStepsRoutable)?.summaryStepRequestEditAmount()
    }

    func summaryStepRequestEditFee() {
        router?.openFeeSelector(viewModel: feeSelector)
    }

    func summaryStepRequestEditProviders() {
        router?.openSwapProvidersSelector(viewModel: providersSelector)
    }
}

extension SendNavigationRouter: SendDestinationStepRoutable {
    func destinationStepFulfilled() {
        (stepsManager as? SendDestinationStepRoutable)?.destinationStepFulfilled()
    }
}

extension SendNavigationRouter: SendNewAmountRoutable {
    func openReceiveTokensList() {
        let tokensListBuilder = sendBaseDataBuilder.makeSendReceiveTokensList()
        router?.openReceiveTokensList(tokensListBuilder: tokensListBuilder)
    }
}

extension SendNavigationRouter: SendModelRoutable {
    func openNetworkCurrency() {
        let (userWalletId, feeTokenItem) = sendBaseDataBuilder.makeFeeCurrencyData()
        router?.openFeeCurrency(userWalletId: userWalletId, feeTokenItem: feeTokenItem)
    }

    func openHighPriceImpactWarningSheetViewModel(viewModel: HighPriceImpactWarningSheetViewModel) {
        router?.openHighPriceImpactWarningSheetViewModel(viewModel: viewModel)
    }

    func resetFlow() {
        stepsManager.resetFlow()
    }
}
