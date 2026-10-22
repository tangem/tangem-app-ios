//
//  CommonPolymarketOwnerAddressProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemPolymarket

final class CommonPolymarketOwnerAddressProvider {
    private let keysRepository: KeysRepository

    init(keysRepository: KeysRepository) {
        self.keysRepository = keysRepository
    }
}

// MARK: - PolymarketOwnerAddressProviding protocol conformance

extension CommonPolymarketOwnerAddressProvider: PolymarketOwnerAddressProviding {
    func getOwnerAddress() -> String? {
        guard let storedKey = PolymarketUtilities.getKey(from: keysRepository) else {
            return nil
        }

        do {
            return try PolymarketUtilities.makeAddress(using: storedKey)
        } catch {
            PolymarketLogger.error("Failed to make the owner address", error: error)
            return nil
        }
    }
}
