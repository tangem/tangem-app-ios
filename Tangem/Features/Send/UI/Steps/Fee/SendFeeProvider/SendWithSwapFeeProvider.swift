//
//  SendWithSwapFeeProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

typealias SendFlowTokenFeeProvider = SendFeeProvider & FeeSelectorInteractor

class SendWithSwapFeeSelectorInteractor {
    private weak var receiveTokenInput: SendReceiveTokenInput?

    private let sendFeeSelectorInteractor: SendFlowTokenFeeProvider
    private let swapFeeSelectorInteractor: SendFlowTokenFeeProvider

    private var receiveTokenPublisher: AnyPublisher<SendReceiveTokenType, Never> {
        receiveTokenInput?.receiveTokenPublisher ?? Empty().eraseToAnyPublisher()
    }

    init(
        receiveTokenInput: SendReceiveTokenInput,
        sendFeeSelectorInteractor: SendFlowTokenFeeProvider,
        swapFeeSelectorInteractor: SendFlowTokenFeeProvider
    ) {
        self.receiveTokenInput = receiveTokenInput
        self.sendFeeSelectorInteractor = sendFeeSelectorInteractor
        self.swapFeeSelectorInteractor = swapFeeSelectorInteractor
    }
}

// MARK: - FeeSelectorInteractor

extension SendWithSwapFeeSelectorInteractor: SendFeeProvider {
    var fees: [TokenFee] { selectorFees }
    var feesPublisher: AnyPublisher<[TokenFee], Never> { selectorFeesPublisher }

    func updateFees() {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.updateFees()
        case .swap: sendFeeSelectorInteractor.updateFees()
        }
    }
}

// MARK: - FeeSelectorInteractor

extension SendWithSwapFeeSelectorInteractor: FeeSelectorInteractor {
    var selectedSelectorFeeTokenItem: TokenItem? {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.selectedSelectorFeeTokenItem
        case .swap: sendFeeSelectorInteractor.selectedSelectorFeeTokenItem
        }
    }

    var selectedSelectorFeeTokenItemPublisher: AnyPublisher<TokenItem?, Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { interactor, receiveToken in
                switch receiveToken {
                case .same: interactor.sendFeeSelectorInteractor.selectedSelectorFeeTokenItemPublisher
                case .swap: interactor.sendFeeSelectorInteractor.selectedSelectorFeeTokenItemPublisher
                }
            }
            .eraseToAnyPublisher()
    }

    var selectorFeeTokenItems: [TokenItem] {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.selectorFeeTokenItems
        case .swap: sendFeeSelectorInteractor.selectorFeeTokenItems
        }
    }

    var selectorFeeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { interactor, receiveToken in
                switch receiveToken {
                case .same: interactor.sendFeeSelectorInteractor.selectorFeeTokenItemsPublisher
                case .swap: interactor.sendFeeSelectorInteractor.selectorFeeTokenItemsPublisher
                }
            }
            .eraseToAnyPublisher()
    }

    var selectedSelectorFee: TokenFee? {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.selectedSelectorFee
        case .swap: sendFeeSelectorInteractor.selectedSelectorFee
        }
    }

    var selectedSelectorFeePublisher: AnyPublisher<TokenFee?, Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { interactor, receiveToken in
                switch receiveToken {
                case .same: interactor.sendFeeSelectorInteractor.selectedSelectorFeePublisher
                case .swap: interactor.sendFeeSelectorInteractor.selectedSelectorFeePublisher
                }
            }
            .eraseToAnyPublisher()
    }

    var selectorFees: [TokenFee] {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.selectorFees
        case .swap: sendFeeSelectorInteractor.selectorFees
        }
    }

    var selectorFeesPublisher: AnyPublisher<[TokenFee], Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { interactor, receiveToken in
                switch receiveToken {
                case .same: interactor.sendFeeSelectorInteractor.selectorFeesPublisher
                case .swap: interactor.sendFeeSelectorInteractor.selectorFeesPublisher
                }
            }
            .eraseToAnyPublisher()
    }

    var customFeeProvider: (any CustomFeeProvider)? {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.customFeeProvider
        case .swap: sendFeeSelectorInteractor.customFeeProvider
        }
    }

    func userDidSelectTokenItem(_ tokenItem: TokenItem) {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.userDidSelectTokenItem(tokenItem)
        case .swap: sendFeeSelectorInteractor.userDidSelectTokenItem(tokenItem)
        }
    }

    func userDidSelectFee(_ fee: TokenFee) {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.userDidSelectFee(fee)
        case .swap: sendFeeSelectorInteractor.userDidSelectFee(fee)
        }
    }
}

class SendWithSwapFeeProvider {
    private weak var receiveTokenInput: SendReceiveTokenInput?

    private let sendFeeProvider: SendFeeProvider
    private let swapFeeProvider: SendFeeProvider

    init(
        receiveTokenInput: SendReceiveTokenInput,
        sendFeeProvider: SendFeeProvider,
        swapFeeProvider: SendFeeProvider
    ) {
        self.receiveTokenInput = receiveTokenInput
        self.sendFeeProvider = sendFeeProvider
        self.swapFeeProvider = swapFeeProvider
    }
}

// MARK: - SendFeeProvider

extension SendWithSwapFeeProvider: SendFeeProvider {
    var fees: [TokenFee] {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeProvider.fees
        case .swap: swapFeeProvider.fees
        }
    }

    var feesPublisher: AnyPublisher<[TokenFee], Never> {
        guard let receiveTokenInput else {
            assertionFailure("ReceiveTokenInput not found")
            return Empty().eraseToAnyPublisher()
        }

        return Publishers.CombineLatest3(
            receiveTokenInput.receiveTokenPublisher,
            sendFeeProvider.feesPublisher,
            swapFeeProvider.feesPublisher
        )
        .map { input, sendFees, swapFees in
            switch input {
            case .same: sendFees
            case .swap: swapFees
            }
        }
        .eraseToAnyPublisher()
    }

    func updateFees() {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeProvider.updateFees()
        case .swap: swapFeeProvider.updateFees()
        }
    }
}
