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
    var fees: [LoadableTokenFee] { selectorFees }
    var feesPublisher: AnyPublisher<[LoadableTokenFee], Never> { selectorFeesPublisher }
    var feesHasMultipleFeeOptions: AnyPublisher<Bool, Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { interactor, receiveToken in
                switch receiveToken {
                case .same: interactor.sendFeeSelectorInteractor.feesHasMultipleFeeOptions
                case .swap: interactor.swapFeeSelectorInteractor.feesHasMultipleFeeOptions
                }
            }
            .eraseToAnyPublisher()
    }

    func updateFees() {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.updateFees()
        case .swap: sendFeeSelectorInteractor.updateFees()
        }
    }
}

// MARK: - FeeSelectorInteractor

extension SendWithSwapFeeSelectorInteractor: FeeSelectorInteractor {
    var selectedSelectorFee: LoadableTokenFee? {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.selectedSelectorFee
        case .swap: swapFeeSelectorInteractor.selectedSelectorFee
        }
    }

    var selectedSelectorFeePublisher: AnyPublisher<LoadableTokenFee?, Never> {
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

    var selectorFees: [LoadableTokenFee] {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.selectorFees
        case .swap: swapFeeSelectorInteractor.selectorFees
        }
    }

    var selectorFeesPublisher: AnyPublisher<[LoadableTokenFee], Never> {
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

    var selectedSelectorTokenFeeProvider: (any TokenFeeProvider)? {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.selectedSelectorTokenFeeProvider
        case .swap: swapFeeSelectorInteractor.selectedSelectorTokenFeeProvider
        }
    }

    var selectedSelectorTokenFeeProviderPublisher: AnyPublisher<(any TokenFeeProvider)?, Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { interactor, receiveToken in
                switch receiveToken {
                case .same: interactor.sendFeeSelectorInteractor.selectedSelectorTokenFeeProviderPublisher
                case .swap: interactor.swapFeeSelectorInteractor.selectedSelectorTokenFeeProviderPublisher
                }
            }
            .eraseToAnyPublisher()
    }

    var selectorTokenFeeProviders: [any TokenFeeProvider] {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.selectorTokenFeeProviders
        case .swap: swapFeeSelectorInteractor.selectorTokenFeeProviders
        }
    }

    var selectorTokenFeeProvidersPublisher: AnyPublisher<[any TokenFeeProvider], Never> {
        receiveTokenPublisher
            .withWeakCaptureOf(self)
            .flatMapLatest { interactor, receiveToken in
                switch receiveToken {
                case .same: interactor.sendFeeSelectorInteractor.selectorTokenFeeProvidersPublisher
                case .swap: interactor.swapFeeSelectorInteractor.selectorTokenFeeProvidersPublisher
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

    func userDidSelect(tokenFeeProvider: any TokenFeeProvider) {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.userDidSelect(tokenFeeProvider: tokenFeeProvider)
        case .swap: swapFeeSelectorInteractor.userDidSelect(tokenFeeProvider: tokenFeeProvider)
        }
    }

    func userDidSelectFee(_ fee: LoadableTokenFee) {
        switch receiveTokenInput?.receiveToken {
        case .none, .same: sendFeeSelectorInteractor.userDidSelectFee(fee)
        case .swap: swapFeeSelectorInteractor.userDidSelectFee(fee)
        }
    }
}
