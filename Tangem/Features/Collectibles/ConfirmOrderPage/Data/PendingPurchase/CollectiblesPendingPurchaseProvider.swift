//
//  CollectiblesPendingPurchaseProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol CollectiblesPendingPurchaseProvider {
    func load() async throws -> CollectiblesPendingPurchase?
}
