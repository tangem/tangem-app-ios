//
//  CollectiblesPrizePoolProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol CollectiblesPrizePoolProvider {
    func load(machineID: String, page: Int) async throws -> CollectiblesPrizePoolPage
}
