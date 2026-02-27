//
//  SendFeeSelectorBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct SendFeeSelectorBuilder {
    let tokenFeeManagerProviding: any TokenFeeProvidersManagerProviding
    let feeSelectorOutput: any FeeSelectorOutput
    let analyticsLogger: any FeeSelectorAnalytics

    func makeSendFeeSelector(router: SendFeeSelectorRoutable) -> SendFeeSelectorViewModel? {
        guard let tokenFeeProvidersManager = tokenFeeManagerProviding.tokenFeeProvidersManager else {
            return nil
        }

        let feeSelectorInteractor = CommonFeeSelectorInteractor(
            tokenFeeProviders: tokenFeeProvidersManager.tokenFeeProviders,
            selectedTokenFeeProvider: tokenFeeProvidersManager.selectedFeeProvider,
            output: feeSelectorOutput
        )

        let feeSelectorViewModel = FeeSelectorBuilder().makeFeeSelectorViewModel(
            feeSelectorInteractor: feeSelectorInteractor,
            analytics: analyticsLogger,
            feeFormatter: CommonFeeFormatter(),
            router: router
        )

        let feeSelector = SendFeeSelectorViewModel(feeSelectorViewModel: feeSelectorViewModel, router: router)
        return feeSelector
    }
}
