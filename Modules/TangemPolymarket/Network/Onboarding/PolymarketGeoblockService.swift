//
//  PolymarketGeoblockService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol PolymarketGeoblockService {
    func geoblock() async throws -> PolymarketGeoblock
}
