//
//  PolymarketOwnerAddressProviding.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol PolymarketOwnerAddressProviding {
    func getOwnerAddress() -> String?

    func deriveOwnerAddress() async throws(PolymarketDerivationError) -> String
}
