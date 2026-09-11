//
//  GachaPacksProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol GachaPacksProvider {
    func load(loreID: String?) async throws -> [GachaPack]
}
