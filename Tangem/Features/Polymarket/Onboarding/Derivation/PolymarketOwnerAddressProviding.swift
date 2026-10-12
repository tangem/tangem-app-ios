//
//  PolymarketOwnerAddressProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

protocol PolymarketOwnerAddressProviding {
    func getOwnerAddress() -> String?

    func deriveOwnerAddress() async throws(PolymarketDerivationError) -> String
}

protocol PolymarketKeysDerivingFactory {
    func makeInteractor() -> KeysDeriving
}

extension KeysDerivingInteractorFactory: PolymarketKeysDerivingFactory {}

struct PolymarketKeysDeriving: PolymarketKeysDerivingFactory {
    private let provider: any KeysDerivingProvider

    init(provider: any KeysDerivingProvider) {
        self.provider = provider
    }

    func makeInteractor() -> KeysDeriving {
        provider.keysDerivingInteractor
    }
}
