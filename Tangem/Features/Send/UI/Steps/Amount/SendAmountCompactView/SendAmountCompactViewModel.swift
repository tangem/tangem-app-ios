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

    init(
        sourceTokenInput: SendSourceTokenInput,
        sourceTokenAmountInput: SendSourceTokenAmountInput,
        receiveTokenInput: SendReceiveTokenInput? = nil,
        receiveTokenAmountInput: SendReceiveTokenAmountInput? = nil,
        swapProvidersInput: SendSwapProvidersInput? = nil
    ) {
        sendAmountCompactViewModel = .init(sourceToken: sourceTokenInput.sourceToken)
        sendAmountCompactViewModel.bind(amountPublisher: sourceTokenAmountInput.sourceAmountPublisher)
        sendAmountCompactViewModel.bind(
            balanceTypePublisher: sourceTokenInput.sourceToken.availableBalanceProvider.formattedBalanceTypePublisher
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
                    receiveToken: $1
                )
            }
            .receiveOnMain()
            .assign(to: &$sendReceiveTokenCompactViewModel)

        Publishers.CombineLatest3(
            receiveTokenInput.receiveTokenPublisher,
            swapProvidersInput.selectedExpressProviderPublisher,
            swapProvidersInput.expressProvidersPublisher
        )
        .withWeakCaptureOf(self)
        .map {
            $0.mapToSendSwapProviderCompactViewData(
                receiveToken: $1.0,
                availableProvider: $1.1,
                providers: $1.2
            )
        }
        .receiveOnMain()
        .assign(to: &$sendSwapProviderCompactViewData)
    }

    private func mapToSendAmountCompactTokenViewModel(
        receiveTokenAmountInput: SendReceiveTokenAmountInput,
        receiveToken: SendReceiveTokenType
    ) -> SendAmountCompactTokenViewModel? {
        switch receiveToken {
        case .same:
            return nil
        case .swap(let receiveToken):
            let viewModel = SendAmountCompactTokenViewModel(receiveToken: receiveToken)
            viewModel.bind(amountPublisher: receiveTokenAmountInput.receiveAmountPublisher)
            viewModel.bind(highPriceImpactPublisher: receiveTokenAmountInput.highPriceImpactPublisher)

            return viewModel
        }
    }

    private func mapToSendSwapProviderCompactViewData(
        receiveToken: SendReceiveTokenType,
        availableProvider: ExpressAvailableProvider?,
        providers: [ExpressAvailableProvider]
    ) -> SendSwapProviderCompactViewData? {
        switch (receiveToken, availableProvider) {
        case (.same, _):
            return nil
        case (.swap, .none):
            return .init(provider: .loading)
        case (.swap, .some(let selectedProvider)):
            let availableProvidersCount = providers.filter(\.isAvailable).count

            let badge = expressProviderFormatter.mapToBadge(availableProvider: selectedProvider)
            let data = SendSwapProviderCompactViewData.ProviderData(
                provider: selectedProvider.provider,
                canSelectAnother: availableProvidersCount > 1,
                badge: badge
            )

            return .init(provider: .success(data))
        }
    }
}
