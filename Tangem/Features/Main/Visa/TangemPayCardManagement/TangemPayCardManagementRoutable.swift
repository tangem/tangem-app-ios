//
//  TangemPayCardManagementRoutable.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

protocol TangemPayCardManagementRoutable: AnyObject {
    func openAddToApplePayGuide(viewModel: TangemPayCardDetailsViewModel)
    func openTangemPaySetPin(tangemPayAccount: TangemPayAccount)
    func openTangemPayCheckPin(tangemPayAccount: TangemPayAccount)
    func openTangemPayFreezeSheet(userWalletId: UserWalletId, freezeAction: @escaping () -> Void)
    func openTangemPayReissueSheet(
        userWalletId: UserWalletId,
        tangemPayAccount: TangemPayAccount,
        onLoadingChange: @escaping (Bool) -> Void,
        onError: @escaping () -> Void
    )
    func openChangeDailyLimit(tangemPayAccount: TangemPayAccount)
}
