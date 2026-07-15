//
//  MarketingCampaignsRepository+InjectionKey.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

private struct MarketingCampaignsRepositoryKey: InjectionKey {
    static var currentValue = MarketingCampaignsRepository()
}

extension InjectedValues {
    var marketingCampaignsRepository: MarketingCampaignsRepository {
        get { Self[MarketingCampaignsRepositoryKey.self] }
        set { Self[MarketingCampaignsRepositoryKey.self] = newValue }
    }
}
