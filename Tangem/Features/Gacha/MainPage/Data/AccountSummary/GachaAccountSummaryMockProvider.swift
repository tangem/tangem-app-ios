//
//  GachaAccountSummaryMockProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct GachaAccountSummaryMockProvider: GachaAccountSummaryProvider {
    func load() async throws -> GachaAccountSummary {
        try await Task.sleep(for: .milliseconds(600))

        return GachaAccountSummary(
            fiatBalance: 2700.52,
            fiatCurrencyCode: "USD",
            cryptoBalance: 2500.52,
            cryptoCurrencyCode: "USDC",
            collectionCardsCount: 25
        )
    }
}
