//
//  TokenSummaryIndicatorsProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol TokenSummaryIndicatorsProvider {
    func loadIndicators(symbol: String) async throws -> [TokenSummaryIndicator]
}
