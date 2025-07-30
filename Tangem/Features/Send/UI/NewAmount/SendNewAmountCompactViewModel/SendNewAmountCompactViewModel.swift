//
//  SendNewAmountCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization
import TangemExpress
import TangemFoundation

protocol SendNewAmountCompactRoutable: AnyObject {
    func userDidTapAmount()
    func userDidTapReceiveTokenAmount()
    func userDidTapSwapProvider()
}

class SendNewAmountCompactViewModel: ObservableObject, Identifiable {
    @Published private(set) var sendAmountCompactViewModel: SendNewAmountCompactTokenViewModel

    @Published private(set) var sendReceiveTokenCompactViewModel: SendNewAmountCompactTokenViewModel?
    @Published private(set) var sendSwapProviderCompactViewData: SendSwapProviderCompactViewData?
    @Published var shouldAnimateBestRateBadge: Bool = true

    var amountsSeparator: SendNewAmountCompactViewSeparator.SeparatorStyle {
        .title(Localization.sendWithSwapTitle)
    }

    weak var router: SendNewAmountCompactRoutable?

    private let expressProviderFormatter: ExpressProviderFormatter = .init()

    init(
        sourceTokenInput: SendSourceTokenInput,
        sourceTokenAmountInput: SendSourceTokenAmountInput,
        receiveTokenInput: SendReceiveTokenInput,
        receiveTokenAmountInput: SendReceiveTokenAmountInput,
        swapProvidersInput: SendSwapProvidersInput
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

// MARK: - SendNewAmountCompactViewModel

private extension SendNewAmountCompactViewModel {
    func bind(receiveTokenInput: SendReceiveTokenInput, receiveTokenAmountInput: SendReceiveTokenAmountInput, swapProvidersInput: SendSwapProvidersInput) {
        receiveTokenInput
            .receiveTokenPublisher
            .withWeakCaptureOf(self)
            .map { $0.mapToSendNewAmountCompactTokenViewModel(receiveTokenAmountInput: receiveTokenAmountInput, receiveToken: $1) }
            .receiveOnMain()
            .assign(to: &$sendReceiveTokenCompactViewModel)

        Publishers.CombineLatest(
            receiveTokenInput.receiveTokenPublisher,
            swapProvidersInput.selectedExpressProviderPublisher,
        )
        .withWeakCaptureOf(self)
        .asyncMap {
            await $0.mapToSendSwapProviderCompactViewData(receiveToken: $1.0, availableProvider: $1.1)
        }
        .receiveOnMain()
        .assign(to: &$sendSwapProviderCompactViewData)
    }

    private func mapToSendNewAmountCompactTokenViewModel(
        receiveTokenAmountInput: SendReceiveTokenAmountInput,
        receiveToken: SendReceiveTokenType
    ) -> SendNewAmountCompactTokenViewModel? {
        switch receiveToken {
        case .same:
            return nil
        case .swap(let receiveToken):
            let viewModel = SendNewAmountCompactTokenViewModel(receiveToken: receiveToken)
            viewModel.bind(amountPublisher: receiveTokenAmountInput.receiveAmountPublisher)

            return viewModel
        }
    }

    private func mapToSendSwapProviderCompactViewData(
        receiveToken: SendReceiveTokenType,
        availableProvider: ExpressAvailableProvider?
    ) async -> SendSwapProviderCompactViewData? {
        switch (receiveToken, availableProvider) {
        case (.same, _):
            return nil
        case (.swap, .none):
            return .init(provider: .loading)
        case (.swap, .some(let selectedProvider)):
            let badge = await expressProviderFormatter.mapToBadge(availableProvider: selectedProvider)
            let data = SendSwapProviderCompactViewData.ProviderData(
                provider: selectedProvider.provider,
                isBest: badge == .bestRate
            )

            return .init(provider: .success(data))
        }
    }
}
