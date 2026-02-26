//
//  ExpressApproveFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

struct ExpressApproveFlowFactory {
    let tokenFeeManagerProviding: (any TokenFeeProvidersManagerProviding)?
    let feeSelectorOutput: (any FeeSelectorOutput)?
    let analyticsLogger: (any FeeSelectorAnalytics)?

    func make(
        input: ExpressApproveViewModel.Input,
        router: ExpressApproveRoutable
    ) -> ExpressApproveFlowViewModel {
        let feeSelectorComponents = makeFeeSelectorComponents()
        return ExpressApproveFlowViewModel(
            input: input,
            router: router,
            feeSelectorViewModel: feeSelectorComponents?.viewModel,
            feeSelectorInteractor: feeSelectorComponents?.interactor,
            feeSelectorOutput: feeSelectorComponents?.output
        )
    }
}

// MARK: - Private

private extension ExpressApproveFlowFactory {
    struct FeeSelectorComponents {
        let viewModel: FeeSelectorTokensViewModel
        let interactor: CommonFeeSelectorInteractor
        let output: any FeeSelectorOutput
    }

    func makeFeeSelectorComponents() -> FeeSelectorComponents? {
        guard let tokenFeeProvidersManager = tokenFeeManagerProviding?.tokenFeeProvidersManager,
              let output = feeSelectorOutput,
              tokenFeeProvidersManager.supportFeeSelection
        else {
            return nil
        }

        let interactor = CommonFeeSelectorInteractor(
            tokenFeeProviders: tokenFeeProvidersManager.tokenFeeProviders,
            selectedTokenFeeProvider: tokenFeeProvidersManager.selectedFeeProvider,
            output: output
        )

        let viewModel = FeeSelectorTokensViewModel(tokensDataProvider: interactor)

        return FeeSelectorComponents(viewModel: viewModel, interactor: interactor, output: output)
    }
}
