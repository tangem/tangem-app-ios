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

    private let flow: SendModel.PredefinedValues.FlowKind

    weak var router: SendNewAmountCompactRoutable?

    private var receiveTokenSubscription: AnyCancellable?

    init(
        flow: SendModel.PredefinedValues.FlowKind,
        sendToken: SendReceiveToken,
        input: SendAmountInput,
        balanceProvider: TokenBalanceProvider
    ) {
        self.flow = flow

        sendAmountCompactViewModel = .init(receiveToken: sendToken)
        sendAmountCompactViewModel.bind(amountPublisher: input.amountPublisher)
        sendAmountCompactViewModel.bind(balanceTypePublisher: balanceProvider.formattedBalanceTypePublisher)
    }

    func userDidTapAmount() {
        router?.userDidTapAmount()
    }

    func userDidTapReceiveTokenAmount() {
        router?.userDidTapReceiveTokenAmount()
    }

    func bind(receiveTokenInput: SendReceiveTokenInput) {
        receiveTokenSubscription = receiveTokenInput.receiveTokenPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, receiveToken in
                viewModel.sendReceiveTokenCompactViewModel = receiveToken.map { .init(receiveToken: $0) }
                viewModel.sendReceiveTokenCompactViewModel?.bind(
                    amountPublisher: receiveTokenInput
                        .receiveAmountPublisher
                        .map { amount in
                            switch amount {
                            case .failure, .loading: nil
                            case .success(let amount): amount
                            }
                        }
                        .eraseToAnyPublisher()
                )

                // [REDACTED_TODO_COMMENT]
                viewModel.sendAmountsSeparator = viewModel.separatorStyle()
            }
    }

    private func separatorStyle() -> SendNewAmountCompactViewSeparator.SeparatorStyle {
        switch flow {
        case .send, .sell, .staking: .title(Localization.sendWithSwapTitle)
        }
    }
}
