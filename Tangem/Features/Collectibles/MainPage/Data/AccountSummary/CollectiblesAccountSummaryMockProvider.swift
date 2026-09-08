//
//  CollectiblesAccountSummaryMockProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct CollectiblesAccountSummaryMockProvider: CollectiblesAccountSummaryProvider {
    func load() async throws -> CollectiblesAccountSummary {
        try await Task.sleep(for: .seconds(1.5))

        return CollectiblesAccountSummary(
            fiatBalance: 2700.52,
            fiatCurrencyCode: "USD",
            cryptoBalance: 2500.52,
            cryptoCurrencyCode: "USDC",
            collectionCardsCount: 25
        )
    }
}
