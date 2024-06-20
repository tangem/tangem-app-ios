//
//  DummyMarketTokenModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct DummyMarketTokenModelFactory {
    func list() -> [MarketsTokenModel] {
        let response = try? JsonUtils.readBundleFile(with: "coinsListResponse", type: MarketsDTO.General.Response.self)
        return response?.tokens ?? []
    }
}
