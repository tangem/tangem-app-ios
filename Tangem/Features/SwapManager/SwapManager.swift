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

/// Will be massive update in [REDACTED_INFO]
class CommonSwapManager {
    private let tokenItem: TokenItem
    private let interactor: ExpressInteractor

    init(tokenItem: TokenItem, interactor: ExpressInteractor) {
        self.tokenItem = tokenItem
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

    func update(receiveToken: TokenItem?, address: String?) {
        guard tokenItem != receiveToken else {
            return
        }

        receiveToken.map {
            interactor.update(destination: SwapManagerDestinationWallet(tokenItem: $0, address: address))
        }
    }

    func update(provider: ExpressAvailableProvider) {
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
