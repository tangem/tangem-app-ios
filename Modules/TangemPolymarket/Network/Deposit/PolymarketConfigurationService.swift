//
//  PolymarketConfigurationService.swift
//  TangemPolymarket
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public protocol PolymarketConfigurationService {
    func builderCode() async throws -> String
}
