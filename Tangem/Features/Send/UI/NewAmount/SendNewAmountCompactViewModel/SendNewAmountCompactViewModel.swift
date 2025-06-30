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
    @Published private(set) var sendAmountCompactViewModel: SendTokenAmountCompactViewModel

    @Published private(set) var sendReceiveTokenCompactViewModel: SendTokenAmountCompactViewModel?
    @Published private(set) var sendSwapProviderCompactViewData: SendSwapProviderCompactViewData?

    var amountsSeparator: SendNewAmountCompactViewSeparator.SeparatorStyle {
        separatorStyle()
    }

    weak var router: SendNewAmountCompactRoutable?

    private let flow: SendModel.PredefinedValues.FlowKind

    private var receiveTokenSubscription: AnyCancellable?
    private var expressProviderSubscription: AnyCancellable?

    init(
        input: SendAmountInput,
        sendToken: SendReceiveToken,
        flow: SendModel.PredefinedValues.FlowKind,
        balanceProvider: TokenBalanceProvider,
        receiveTokenInput: SendReceiveTokenInput,
        swapProvidersInput: SendSwapProvidersInput
    ) {
        self.flow = flow

        sendAmountCompactViewModel = .init(receiveToken: sendToken)
        sendAmountCompactViewModel.bind(amountPublisher: input.amountPublisher)
        sendAmountCompactViewModel.bind(balanceTypePublisher: balanceProvider.formattedBalanceTypePublisher)

        bind(receiveTokenInput: receiveTokenInput, swapProvidersInput: swapProvidersInput)
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
    func bind(receiveTokenInput: SendReceiveTokenInput, swapProvidersInput: SendSwapProvidersInput) {
        receiveTokenSubscription = receiveTokenInput
            .receiveTokenPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.updateView(receiveTokenInput: receiveTokenInput, receiveToken: $1) }

        expressProviderSubscription = Publishers.CombineLatest(
            receiveTokenInput.receiveTokenPublisher,
            swapProvidersInput.selectedExpressProviderPublisher,
        )
        .withWeakCaptureOf(self)
        .receiveOnMain()
        .sink { $0.updateView(receiveToken: $1.0, availableProvider: $1.1) }
    }

    private func separatorStyle() -> SendNewAmountCompactViewSeparator.SeparatorStyle {
        switch flow {
        case .send, .sell, .staking: .title(Localization.sendWithSwapTitle)
        }
    }

    private func updateView(receiveTokenInput: SendReceiveTokenInput, receiveToken: SendReceiveTokenType) {
        switch receiveToken {
        case .same:
            sendReceiveTokenCompactViewModel = nil
            sendSwapProviderCompactViewData = nil
        case .swap(let receiveToken):
            let amountPublisher = receiveTokenInput
                .receiveAmountPublisher
                .map { $0.value?.flatMap { $0 } }
                .eraseToAnyPublisher()

            sendReceiveTokenCompactViewModel = .init(receiveToken: receiveToken)
            sendReceiveTokenCompactViewModel?.bind(amountPublisher: amountPublisher)
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
