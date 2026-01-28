//
//  AccountModelAnalyticsProviding+ParameterEnrichment.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

extension AccountModelAnalyticsProviding {
    /// Enriches the given analytics parameters dictionary with account-specific analytics data.
    ///
    /// - Parameters:
    ///   - parameters: The analytics parameters dictionary to enrich (modified in place)
    ///   - builder: Analytics builder to use for extracting account parameters
    func enrichAnalyticsParameters(
        _ parameters: inout [Analytics.ParameterKey: String],
        using builder: AccountsAnalyticsBuilder
    ) {
        let accountParams = analyticsParameters(with: builder)
        parameters.merge(accountParams) { $1 }
    }
}
