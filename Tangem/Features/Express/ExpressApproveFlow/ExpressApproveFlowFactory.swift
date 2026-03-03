//
//  ExpressApproveFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemFoundation

struct ExpressApproveFlowFactory {
    let approveInput: ExpressApproveViewModel.Input
    let tokenFeeManagerProviding: any TokenFeeProvidersManagerProviding
    let allowanceService: (any AllowanceService)?
    let approveAmount: Decimal?
    let spender: String?

    func make(router: ExpressApproveRoutable) -> ExpressApproveFlowViewModel? {
        guard let tokenFeeProvidersManager = tokenFeeManagerProviding.tokenFeeProvidersManager else {
            return nil
        }

        let interactor = CommonFeeSelectorInteractor(
            tokenFeeProviders: tokenFeeProvidersManager.tokenFeeProviders,
            selectedTokenFeeProvider: tokenFeeProvidersManager.selectedFeeProvider,
            output: nil
        )

        let approveViewModel = ExpressApproveViewModel(input: approveInput)

        return ExpressApproveFlowViewModel(
            approveViewModel: approveViewModel,
            router: router,
            feeSelectorViewModel: FeeSelectorTokensViewModel(tokensDataProvider: interactor),
            feeSelectorInteractor: interactor,
            allowanceService: allowanceService,
            approveAmount: approveAmount,
            spender: spender
        )
    }
}
