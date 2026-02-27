//
//  SendGenericModelRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

/// Uses for connect `TransferModel` -> `SendViewModel(Base)`
protocol TransferModelRoutable: AnyObject {
    func openNetworkCurrency()
    func openApproveSheet()
}

/// Uses for connect `SendWithSwapModel` -> `SendViewModel(Base)`
protocol SendWithSwapModelRoutable: TransferModelRoutable {
    func openHighPriceImpactWarningSheetViewModel(viewModel: HighPriceImpactWarningSheetViewModel)
    func resetFlow()
}

/// Uses for connect `SwapModel` -> `SendViewModel(Base)`
protocol SwapModelRoutable: TransferModelRoutable {
    func performSwapAction()
}

/// Uses for connect `StakingModel` -> `SendViewModel(Base)`
protocol StakingModelRoutable: TransferModelRoutable {
    func openAccountInitializationFlow(viewModel: BlockchainAccountInitializationViewModel)
}
