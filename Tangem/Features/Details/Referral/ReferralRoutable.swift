//
//  ReferralRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

protocol ReferralRoutable: AnyObject {
    func openTOS(with url: URL)
    func dismiss()
    @MainActor
    func showAccountSelector(
        selectedAccount: any BaseAccountModel,
        userWalletModel: UserWalletModel,
        cryptoAccountModelsFilter: @escaping (any CryptoAccountModel) -> Bool,
        onSelect: @escaping (any CryptoAccountModel) -> Void
    )
}
