//
//  SendAmountCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import TangemExpress
import TangemFoundation

protocol SendAmountCompactRoutable: AnyObject {
    func userDidTapAmount()
    func userDidTapReceiveTokenAmount()
    func userDidTapSwapProvider()
}

class SendAmountCompactViewModel: ObservableObject, Identifiable {
    @Published private(set) var sendAmountCompactViewModel: SendAmountCompactTokenViewModel

    @Published private(set) var sendReceiveTokenCompactViewModel: SendAmountCompactTokenViewModel?
    @Published private(set) var sendSwapProviderCompactViewData: SendSwapProviderCompactViewData?
    @Published var shouldAnimateBestRateBadge: Bool = true

    var amountsSeparator: SendAmountCompactViewSeparator.SeparatorStyle {
        .title(Localization.sendWithSwapTitle)
    }

    weak var router: SendAmountCompactRoutable?

    private let expressProviderFormatter: ExpressProviderFormatter = .init()
    private let isReceiveAmountApproximatePublisher: AnyPublisher<Bool, Never>?

    init(
        initialSourceToken: SendSourceToken,
        actionType: SendFlowActionType,
        sourceTokenInput: SendSourceTokenInput,
        sourceTokenAmountInput: SendSourceTokenAmountInput,
        receiveTokenInput: SendReceiveTokenInput? = nil,
        receiveTokenAmountInput: SendReceiveTokenAmountInput? = nil,
        swapProvidersInput: SendSwapProvidersInput? = nil,
        isReceiveAmountApproximatePublisher: AnyPublisher<Bool, Never>? = nil
    ) {
        self.isReceiveAmountApproximatePublisher = isReceiveAmountApproximatePublisher
        sendAmountCompactViewModel = .init(sourceToken: initialSourceToken, actionType: actionType)
        sendAmountCompactViewModel.bind(amountPublisher: sourceTokenAmountInput.sourceAmountPublisher, isApproximateAmount: false)
        sendAmountCompactViewModel.bind(
            balanceTypePublisher: initialSourceToken.availableBalanceProvider.formattedBalanceTypePublisher
        )

        bind(
            receiveTokenInput: receiveTokenInput,
            receiveTokenAmountInput: receiveTokenAmountInput,
            swapProvidersInput: swapProvidersInput
        )
    }

    func userDidTapAmount() {
        router?.userDidTapAmount()
    }

    func userDidTapReceiveTokenAmount() {
        router?.userDidTapReceiveTokenAmount()
    }

    func userDidTapProvider() {
        router?.userDidTapSwapProvider()
    }
}

// MARK: - SendAmountCompactViewModel

private extension SendAmountCompactViewModel {
    func bind(
        receiveTokenInput: SendReceiveTokenInput?,
        receiveTokenAmountInput: SendReceiveTokenAmountInput?,
        swapProvidersInput: SendSwapProvidersInput?
    ) {
        guard let receiveTokenInput, let receiveTokenAmountInput, let swapProvidersInput else {
            return
        }

        receiveTokenInput
            .receiveTokenPublisher
            .withWeakCaptureOf(self)
            .map {
                $0.mapToSendAmountCompactTokenViewModel(
                    receiveTokenAmountInput: receiveTokenAmountInput,
                    receiveToken: $1.value
                )
            }
            .receiveOnMain()
            .assign(to: &$sendReceiveTokenCompactViewModel)

        Publishers.CombineLatest4(
            receiveTokenInput.receiveTokenPublisher,
            swapProvidersInput.selectedExpressProviderPublisher.map { $0?.value },
            swapProvidersInput.expressProvidersPublisher,
            receiveTokenAmountInput.highPriceImpactPublisher
        )
        .withWeakCaptureOf(self)
        .map {
            $0.mapToSendSwapProviderCompactViewData(
                receiveToken: $1.0.value,
                availableProvider: $1.1,
                providers: $1.2,
                hasHighPriceImpactWarning: $1.3.map { !$0.level.isNegligible } ?? false
            )
        }
        .receiveOnMain()
        .assign(to: &$sendSwapProviderCompactViewData)
    }

    private func mapToSendAmountCompactTokenViewModel(
        receiveTokenAmountInput: SendReceiveTokenAmountInput,
        receiveToken: SendReceiveToken?
    ) -> SendAmountCompactTokenViewModel? {
        switch receiveToken {
        case .none:
            return nil
        case .some(let receiveToken):
            let viewModel = SendAmountCompactTokenViewModel(receiveToken: receiveToken)
            viewModel.bind(
                amountPublisher: receiveTokenAmountInput.receiveAmountPublisher,
                isApproximateAmount: true,
                isApproximateAmountPublisher: isReceiveAmountApproximatePublisher
            )
            viewModel.bind(highPriceImpactPublisher: receiveTokenAmountInput.highPriceImpactPublisher)

            return viewModel
        }
    }

    private func mapToSendSwapProviderCompactViewData(
        receiveToken: SendReceiveToken?,
        availableProvider: ExpressAvailableProvider?,
        providers: [ExpressAvailableProvider],
        hasHighPriceImpactWarning: Bool
    ) -> SendSwapProviderCompactViewData? {
        switch (receiveToken, availableProvider) {
        case (.none, _):
            return nil
        case (.some, .none):
            return .init(provider: .loading)
        case (.some, .some(let selectedProvider)):
            let canSelectAnother = providers.count > 1

            let badge = expressProviderFormatter.mapToBadge(availableProvider: selectedProvider, hasHighPriceImpactWarning: hasHighPriceImpactWarning)
            let data = SendSwapProviderCompactViewData.ProviderData(
                provider: selectedProvider.provider,
                canSelectAnother: canSelectAnother,
                badge: badge
            )

            return .init(provider: .success(data))
        }
    }
}
