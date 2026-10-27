//
//  ApproveFlowFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress
import TangemFoundation
import TangemUI

struct ApproveFlowFactory {
    let approveInput: ApproveViewModel.Input
    let signingActionButtonType: SigningActionButtonViewType

    func make(router: ApproveRoutable) -> ApproveFlowViewModel {
        var feeSelectorViewModel: FeeSelectorTokensViewModel?

        if approveInput.supportFeeSelection {
            feeSelectorViewModel = FeeSelectorTokensViewModel(tokensDataProvider: approveInput.interactor)
        }

        let approveViewModel = ApproveViewModel(input: approveInput)

        return ApproveFlowViewModel(
            approveViewModel: approveViewModel,
            router: router,
            feeSelectorViewModel: feeSelectorViewModel,
            interactor: approveInput.interactor,
            signingActionButtonType: signingActionButtonType
        )
    }
}
