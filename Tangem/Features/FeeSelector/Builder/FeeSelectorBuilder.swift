//
//  FeeSelectorBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct FeeSelectorBuilder {
    func makeFeeSelectorViewModel(
        feeSelectorInteractor: any FeeSelectorInteractor,
        customFeeAvailabilityProvider: (any FeeSelectorCustomFeeAvailabilityProvider)?,
        mapper: any FeeSelectorFeesViewModelMapper,
        analytics: any FeeSelectorAnalytics,
        output: any FeeSelectorOutput,
        router: any FeeSelectorRoutable
    ) -> FeeSelectorViewModel {
        FeeSelectorViewModel(
            interactor: feeSelectorInteractor,
            summaryViewModel: FeeSelectorSummaryViewModel(
                tokensDataProvider: feeSelectorInteractor,
                feesDataProvider: feeSelectorInteractor
            ),
            tokensViewModel: FeeSelectorTokensViewModel(
                tokensDataProvider: feeSelectorInteractor
            ),
            feesViewModel: FeeSelectorFeesViewModel(
                provider: feeSelectorInteractor,
                mapper: mapper,
                customFeeAvailabilityProvider: customFeeAvailabilityProvider,
                analytics: analytics
            ),
            router: router,
        )
    }
}
