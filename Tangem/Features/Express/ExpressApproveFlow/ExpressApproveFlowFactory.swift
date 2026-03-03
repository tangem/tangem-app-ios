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

    func make(router: ExpressApproveRoutable) -> ExpressApproveFlowViewModel {
        let approveViewModel = ExpressApproveViewModel(input: approveInput)

        var feeSelectorViewModel: FeeSelectorTokensViewModel?
        var feeSelectorInteractor: CommonFeeSelectorInteractor?

        if let tokenFeeProvidersManager = tokenFeeManagerProviding.tokenFeeProvidersManager {
            let interactor = CommonFeeSelectorInteractor(
                tokenFeeProviders: tokenFeeProvidersManager.tokenFeeProviders,
                selectedTokenFeeProvider: tokenFeeProvidersManager.selectedFeeProvider,
                output: nil
            )
            feeSelectorInteractor = interactor
            feeSelectorViewModel = FeeSelectorTokensViewModel(tokensDataProvider: interactor)
        }

        return ExpressApproveFlowViewModel(
            approveViewModel: approveViewModel,
            router: router,
            feeSelectorViewModel: feeSelectorViewModel,
            feeSelectorInteractor: feeSelectorInteractor,
            allowanceService: allowanceService,
            approveAmount: approveAmount,
            spender: spender
        )
    }
}
