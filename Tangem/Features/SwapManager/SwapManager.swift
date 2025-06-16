//
//  SwapManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemExpress

class CommonSwapManager {
    private let mode: SwapDestinationMode
    private let interactor: ExpressInteractor

    private var recipientToken: TokenItem?
    private var recipientAddress: String?

    init(mode: SwapDestinationMode, interactor: ExpressInteractor) {
        self.mode = mode
        self.interactor = interactor
    }
}

// MARK: - SwapManager

extension CommonSwapManager: SwapManager {
    var swappingPair: SwapManagerSwappingPair {
        interactor.getSwappingPair()
    }

    var state: SwapManagerState {
        interactor.getState()
    }

    var statePublisher: AnyPublisher<ExpressInteractor.State, Never> {
        interactor.state
    }

    var swappingPairPublisher: AnyPublisher<SwapManagerSwappingPair, Never> {
        interactor.swappingPair
    }

    func update(amount: Decimal?) {
        interactor.update(amount: amount, by: .amountChange)
    }

    func update(receiveToken: SendReceiveToken?) {
        // [REDACTED_TODO_COMMENT]
    }

    func update(receiveAddress: String?) {
        // [REDACTED_TODO_COMMENT]
    }

    func updateProvider(provider: ExpressAvailableProvider) {
        interactor.updateProvider(provider: provider)
    }
}

// MARK: - Private

private extension CommonSwapManager {}

extension CommonSwapManager {
    enum SwapDestinationMode {
        case onMyWallet(address: String)
        case toAnotherWallet
    }
}
