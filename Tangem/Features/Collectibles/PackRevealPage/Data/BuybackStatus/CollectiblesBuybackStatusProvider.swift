//
//  CollectiblesBuybackStatusProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol CollectiblesBuybackStatusProvider {
    func load(buybackID: String) async throws -> CollectiblesBuybackStatus
}
