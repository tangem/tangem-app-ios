//
//  SendNewAmountCompactViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemLocalization

protocol SendNewAmountCompactRoutable: AnyObject {
    func userDidTapAmount()
    func userDidTapReceiveTokenAmount()
}

class SendNewAmountCompactViewModel: ObservableObject, Identifiable {
    @Published private(set) var sendAmountCompactViewModel: SendTokenAmountCompactViewModel
    @Published private(set) var sendAmountsSeparator: SendNewAmountCompactViewSeparator.SeparatorStyle?
    @Published private(set) var sendReceiveTokenCompactViewModel: SendTokenAmountCompactViewModel?

    weak var router: SendNewAmountCompactRoutable?

    private let flow: SendModel.PredefinedValues.FlowKind
    private weak var receiveTokenInput: SendReceiveTokenInput?

    private var receiveTokenSubscription: AnyCancellable?

    init(
        input: SendAmountInput,
        sendToken: SendReceiveToken,
        flow: SendModel.PredefinedValues.FlowKind,
        balanceProvider: TokenBalanceProvider,
        receiveTokenInput: SendReceiveTokenInput?
    ) {
        self.flow = flow
        self.receiveTokenInput = receiveTokenInput

        sendAmountCompactViewModel = .init(receiveToken: sendToken)
        sendAmountCompactViewModel.bind(amountPublisher: input.amountPublisher)
        sendAmountCompactViewModel.bind(balanceTypePublisher: balanceProvider.formattedBalanceTypePublisher)

        bind()
    }

    func userDidTapAmount() {
        router?.userDidTapAmount()
    }

    func userDidTapReceiveTokenAmount() {
        router?.userDidTapReceiveTokenAmount()
    }
}

// MARK: - SendNewAmountCompactViewModel

private extension SendNewAmountCompactViewModel {
    func bind() {
        receiveTokenSubscription = receiveTokenInput?.receiveTokenPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { $0.updateView(receiveToken: $1) }
    }

    private func separatorStyle() -> SendNewAmountCompactViewSeparator.SeparatorStyle {
        switch flow {
        case .send, .sell, .staking: .title(Localization.sendWithSwapTitle)
        }
    }

    private func updateView(receiveToken: SendReceiveTokenType) {
        switch receiveToken {
        case .same:
            sendReceiveTokenCompactViewModel = nil
            sendAmountsSeparator = nil
        case .swap(let receiveToken):
            guard let receiveTokenInput else {
                return
            }

            let amountPublisher = receiveTokenInput
                .receiveAmountPublisher
                .map { $0.value?.flatMap { $0 } }
                .eraseToAnyPublisher()

            sendReceiveTokenCompactViewModel = .init(receiveToken: receiveToken)
            sendReceiveTokenCompactViewModel?.bind(amountPublisher: amountPublisher)
            sendAmountsSeparator = separatorStyle()
        }
    }
}
