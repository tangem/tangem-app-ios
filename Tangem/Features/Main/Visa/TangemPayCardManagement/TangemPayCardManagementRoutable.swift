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
    func openTangemPaySetPin(card: TangemPayCard)
    func openTangemPayCheckPin(card: TangemPayCard)
    func openTangemPayFreezeSheet(userWalletId: UserWalletId, freezeAction: @escaping () -> Void)
    func openTangemPayReissueSheet(
        userWalletId: UserWalletId,
        card: TangemPayCard,
        onError: @escaping () -> Void
    )
    func openChangeDailyLimit(card: TangemPayCard)
    func popToCardListScreen()
}
