//
//  ExpressApproveFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

struct ExpressApproveFlowFactory {
    let approveInput: ExpressApproveViewModel.Input
    let tokenFeeManagerProviding: any TokenFeeProvidersManagerProviding
    let allowanceService: (any AllowanceService)?

    func make(router: ExpressApproveRoutable) -> ExpressApproveFlowViewModel? {
        guard let tokenFeeProvidersManager = tokenFeeManagerProviding.tokenFeeProvidersManager else {
            return nil
        }

        let interactor = CommonFeeSelectorInteractor(
            tokenFeeProviders: tokenFeeProvidersManager.tokenFeeProviders,
            selectedTokenFeeProvider: tokenFeeProvidersManager.selectedFeeProvider
        )

        let approveViewModel = ExpressApproveViewModel(input: approveInput)

        return ExpressApproveFlowViewModel(
            approveViewModel: approveViewModel,
            router: router,
            feeSelectorViewModel: FeeSelectorTokensViewModel(tokensDataProvider: interactor),
            feeSelectorInteractor: interactor,
            allowanceService: allowanceService
        )
    }
}
