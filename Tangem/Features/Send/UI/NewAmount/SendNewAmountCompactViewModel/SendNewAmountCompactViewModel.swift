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

    var amountsSeparator: SendNewAmountCompactViewSeparator.SeparatorStyle {
        .title(Localization.sendWithSwapTitle)
    }

    weak var router: SendNewAmountCompactRoutable?

    private var receiveTokenSubscription: AnyCancellable?
    private var expressProviderSubscription: AnyCancellable?

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
        receiveTokenSubscription = receiveTokenInput
            .receiveTokenPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.updateView(receiveTokenAmountInput: receiveTokenAmountInput, receiveToken: $1) }

        expressProviderSubscription = Publishers.CombineLatest(
            receiveTokenInput.receiveTokenPublisher,
            swapProvidersInput.selectedExpressProviderPublisher,
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { $0.updateView(receiveToken: $1.0, availableProvider: $1.1) }
    }

    private func updateView(receiveTokenAmountInput: SendReceiveTokenAmountInput, receiveToken: SendReceiveTokenType) {
        switch receiveToken {
        case .same:
            sendReceiveTokenCompactViewModel = nil
            sendSwapProviderCompactViewData = nil
        case .swap(let receiveToken):
            sendReceiveTokenCompactViewModel = .init(receiveToken: receiveToken)
            sendReceiveTokenCompactViewModel?.bind(amountPublisher: receiveTokenAmountInput.receiveAmountPublisher)
        }
    }

    private func updateView(receiveToken: SendReceiveTokenType, availableProvider: ExpressAvailableProvider?) {
        switch (receiveToken, availableProvider) {
        case (.same, _):
            sendSwapProviderCompactViewData = nil
        case (.swap, .none):
            sendSwapProviderCompactViewData = .init(provider: .loading)
        case (.swap, .some(let selectedProvider)):
            sendSwapProviderCompactViewData = .init(provider: .success(selectedProvider.provider))
        }
    }
}
