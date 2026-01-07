//
//  FeeSelectorBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct FeeSelectorBuilder {
    func makeFeeSelectorViewModel(
        tokensDataProvider: any FeeSelectorTokensDataProvider,
        feesDataProvider: any FeeSelectorFeesDataProvider,
        customFeeAvailabilityProvider: (any FeeSelectorCustomFeeAvailabilityProvider)?,
        mapper: any FeeSelectorFeesViewModelMapper,
        analytics: any FeeSelectorAnalytics,
        output: any FeeSelectorOutput,
        router: any FeeSelectorRoutable
    ) -> FeeSelectorViewModel {
        FeeSelectorViewModel(
            summaryViewModel: FeeSelectorSummaryViewModel(
                tokensDataProvider: tokensDataProvider,
                feesDataProvider: feesDataProvider
            ),
            tokensViewModel: FeeSelectorTokensViewModel(tokensDataProvider: tokensDataProvider),
            feesViewModel: FeeSelectorFeesViewModel(
                provider: feesDataProvider,
                mapper: mapper,
                customFeeAvailabilityProvider: customFeeAvailabilityProvider,
                analytics: analytics
            ),
            output: output,
            router: router,
        )
    }
}
