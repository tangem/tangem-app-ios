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
        analytics: any FeeSelectorAnalytics,
        feeFormatter: any FeeFormatter,
        router: any FeeSelectorRoutable,
    ) -> FeeSelectorViewModel {
        FeeSelectorViewModel(
            interactor: feeSelectorInteractor,
            summaryViewModel: FeeSelectorSummaryViewModel(
                tokensDataProvider: feeSelectorInteractor,
                feesDataProvider: feeSelectorInteractor,
                feeFormatter: feeFormatter
            ),
            tokensViewModel: FeeSelectorTokensViewModel(
                tokensDataProvider: feeSelectorInteractor,
            ),
            feesViewModel: FeeSelectorFeesViewModel(
                provider: feeSelectorInteractor,
                customFeeDataProvider: feeSelectorInteractor,
                feeFormatter: feeFormatter,
            ),
            router: router,
            analytics: analytics
        )
    }
}
