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
        customFeeAvailabilityProvider: (any FeeSelectorCustomFeeAvailabilityProvider)? = nil,
        mapper: any FeeSelectorFeesViewModelMapper,
        analytics: any FeeSelectorAnalytics,
        router: any FeeSelectorRoutable
    ) -> FeeSelectorViewModel {
        FeeSelectorViewModel(
            interactor: feeSelectorInteractor,
            summaryViewModel: FeeSelectorSummaryViewModel(
                interactor: feeSelectorInteractor,
            ),
            tokensViewModel: FeeSelectorTokensViewModel(
                interactor: feeSelectorInteractor
            ),
            feesViewModel: FeeSelectorFeesViewModel(
                interactor: feeSelectorInteractor,
                mapper: mapper,
                customFeeAvailabilityProvider: customFeeAvailabilityProvider,
                analytics: analytics
            ),
            router: router,
        )
    }
}
