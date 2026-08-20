//
//  TangemPayAddFundsSheetRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemPay

protocol TangemPayAddFundsSheetRoutable: AnyObject {
    func addFundsSheetRequestReceive(viewModel: ReceiveMainViewModel)
    func addFundsSheetRequestChooseNetwork(networks: [TangemPayBalance.Network])
    func addFundsSheetRequestSwap(input: PredefinedSwapParameters)
    func addFundsSheetRequestBankTransfer()

    func closeAddFundsSheet()
}
