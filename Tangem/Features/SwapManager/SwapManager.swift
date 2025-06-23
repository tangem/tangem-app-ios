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
    private let interactor: ExpressInteractor

    init(interactor: ExpressInteractor) {
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

    func update(destination: TokenItem?, address: String?) {
        let destinationWallet = destination.map {
            SwapManagerDestinationWallet(tokenItem: $0, address: address)
        }

        interactor.update(destination: destinationWallet)
    }

    func update(provider: ExpressAvailableProvider) {
        interactor.updateProvider(provider: provider)
    }
}

// MARK: - Private

private extension CommonSwapManager {}

struct SwapManagerDestinationWallet: ExpressInteractorDestinationWallet {
    var id: WalletModelId { .init(tokenItem: tokenItem) }
    var isCustom: Bool { false }
    var currency: TangemExpress.ExpressWalletCurrency { tokenItem.expressCurrency }

    let tokenItem: TokenItem
    let address: String?

    init(tokenItem: TokenItem, address: String?) {
        self.tokenItem = tokenItem
        self.address = address
    }
}
