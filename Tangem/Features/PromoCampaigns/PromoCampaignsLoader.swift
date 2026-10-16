//
//  PromoCampaignsLoader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

protocol PromoCampaignsLoading {
    func loadPromoCampaigns(for wallet: PromoCampaignWallet) async throws -> [PromoCampaign]
}

struct CommonPromoCampaignsLoader {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let mapper = PromoCampaignMapper()
}

// MARK: - PromoCampaignsLoading

extension CommonPromoCampaignsLoader: PromoCampaignsLoading {
    func loadPromoCampaigns(for wallet: PromoCampaignWallet) async throws -> [PromoCampaign] {
        let request = PromoCampaignsDTO.Request(wallet: wallet, language: Localization.languageCode)

        return try await tangemApiService
            .loadPromoCampaigns(request: request)
            .map(mapper.mapToPromoCampaign(from:))
    }
}
