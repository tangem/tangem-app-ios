//
//  SendGenericModelRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Uses for connect `SendModel` -> `SendViewModel(Base)`
protocol SendModelRoutable: AnyObject {
    func openNetworkCurrency()
    func openApproveSheet()
}

/// Uses for connect `SendWithSwapModel` -> `SendViewModel(Base)`
protocol SendWithSwapModelRoutable: SendModelRoutable {
    func openHighPriceImpactWarningSheetViewModel(viewModel: HighPriceImpactWarningSheetViewModel)
    func resetFlow()
}

/// Uses for connect `SwapModel` -> `SendViewModel(Base)`
protocol SwapModelRoutable: SendModelRoutable {
    func performSwapAction()
}

/// Uses for connect `StakingModel` -> `SendViewModel(Base)`
protocol StakingModelRoutable: SendModelRoutable {
    func openAccountInitializationFlow(viewModel: BlockchainAccountInitializationViewModel)
}
