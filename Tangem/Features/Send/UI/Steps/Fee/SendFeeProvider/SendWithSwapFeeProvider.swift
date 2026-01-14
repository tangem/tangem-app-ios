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
        case .swap: swapFeeSelectorInteractor.selectedSelectorFeeTokenItem
        }
    }

    var selectedSelectorFeeTokenItemPublisher: AnyPublisher<TokenItem?, Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { interactor, receiveToken in
                switch receiveToken {
                case .same: interactor.sendFeeSelectorInteractor.selectedSelectorFeeTokenItemPublisher
                case .swap: interactor.swapFeeSelectorInteractor.selectedSelectorFeeTokenItemPublisher
                }
            }
            .eraseToAnyPublisher()
    }

    var selectorFeeTokenItems: [TokenItem] {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.selectorFeeTokenItems
        case .swap: swapFeeSelectorInteractor.selectorFeeTokenItems
        }
    }

    var selectorFeeTokenItemsPublisher: AnyPublisher<[TokenItem], Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { interactor, receiveToken in
                switch receiveToken {
                case .same: interactor.sendFeeSelectorInteractor.selectorFeeTokenItemsPublisher
                case .swap: interactor.swapFeeSelectorInteractor.selectorFeeTokenItemsPublisher
                }
            }
            .eraseToAnyPublisher()
    }

    var selectedSelectorFee: TokenFee? {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.selectedSelectorFee
        case .swap: swapFeeSelectorInteractor.selectedSelectorFee
        }
    }

    var selectedSelectorFeePublisher: AnyPublisher<TokenFee?, Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { interactor, receiveToken in
                switch receiveToken {
                case .same: interactor.sendFeeSelectorInteractor.selectedSelectorFeePublisher
                case .swap: interactor.swapFeeSelectorInteractor.selectedSelectorFeePublisher
                }
            }
            .eraseToAnyPublisher()
    }

    var selectorFees: [TokenFee] {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.selectorFees
        case .swap: swapFeeSelectorInteractor.selectorFees
        }
    }

    var selectorFeesPublisher: AnyPublisher<[TokenFee], Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { interactor, receiveToken in
                switch receiveToken {
                case .same: interactor.sendFeeSelectorInteractor.selectorFeesPublisher
                case .swap: interactor.swapFeeSelectorInteractor.selectorFeesPublisher
                }
            }
            .eraseToAnyPublisher()
    }

    var customFeeProvider: (any CustomFeeProvider)? {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.customFeeProvider
        case .swap: swapFeeSelectorInteractor.customFeeProvider
        }
    }

    func userDidSelectTokenItem(_ tokenItem: TokenItem) {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.userDidSelectTokenItem(tokenItem)
        case .swap: swapFeeSelectorInteractor.userDidSelectTokenItem(tokenItem)
        }
    }

    func userDidSelectFee(_ fee: TokenFee) {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.userDidSelectFee(fee)
        case .swap: swapFeeSelectorInteractor.userDidSelectFee(fee)
        }
    }
}
