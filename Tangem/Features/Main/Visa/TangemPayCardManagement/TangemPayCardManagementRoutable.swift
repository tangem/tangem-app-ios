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
    func openTangemPaySetPin(tangemPayAccount: TangemPayAccount)
    func openTangemPaySetPin(card: TangemPayCard)

    func openTangemPayCheckPin(tangemPayAccount: TangemPayAccount)
    func openTangemPayCheckPin(card: TangemPayCard)

    func openTangemPayFreezeSheet(userWalletId: UserWalletId, freezeAction: @escaping () -> Void)
    func openTangemPayUnfreezeSheet(userWalletId: UserWalletId, unfreezeAction: @escaping () -> Void)

    func openTangemPayBiometryNotSetSheet()

    func openTangemPayReissueSheet(
        userWalletId: UserWalletId,
        tangemPayAccount: TangemPayAccount,
        onLoadingChange: @escaping (Bool) -> Void,
        onError: @escaping () -> Void
    )
    func openTangemPayReissueSheet(
        userWalletId: UserWalletId,
        card: TangemPayCard,
        onLoadingChange: @escaping (Bool) -> Void,
        onError: @escaping () -> Void
    )
    func openTangemPayCloseCardSheet(
        userWalletId: UserWalletId,
        card: TangemPayCard,
        onError: @escaping () -> Void
    )

    func openChangeDailyLimit(tangemPayAccount: TangemPayAccount)
    func openChangeDailyLimit(card: TangemPayCard)

    func popToCardListScreen()
}
