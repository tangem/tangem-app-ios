//
//  TangemPayMainRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol TangemPayMainRoutable: AnyObject {
    func openAddToApplePayGuide(viewModel: TangemPayCardDetailsViewModel)

    func openTangemPayAddFundsSheet(input: TangemPayAddFundsSheetViewModel.Input)
    func openTangemPayNoDepositAddressSheet()
    func openTangemPayFreezeSheet(freezeAction: @escaping () -> Void)
    func openTangemPayPin()
}
