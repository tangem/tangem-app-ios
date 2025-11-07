//
//  TangemPayAddFundsSheetRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol TangemPayAddFundsSheetRoutable: AnyObject {
    func addFundsSheetRequestReceive(viewModel: ReceiveMainViewModel)
    func addFundsSheetRequestSwap(input: ExpressDependenciesDestinationInput)

    func closeAddFundsSheet()
}
