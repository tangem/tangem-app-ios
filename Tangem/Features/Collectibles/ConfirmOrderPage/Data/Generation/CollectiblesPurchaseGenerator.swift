//
//  CollectiblesPurchaseGenerator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol CollectiblesPurchaseGenerator {
    func generate(
        machineID: String,
        fromAddress: String,
        toAddress: String
    ) async throws -> CollectiblesGeneratedPurchase
}
