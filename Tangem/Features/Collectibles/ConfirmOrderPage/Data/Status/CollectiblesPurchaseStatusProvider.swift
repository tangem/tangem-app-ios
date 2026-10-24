//
//  CollectiblesPurchaseStatusProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol CollectiblesPurchaseStatusProvider {
    func load(txID: String) async throws -> CollectiblesPurchaseTransaction
}
