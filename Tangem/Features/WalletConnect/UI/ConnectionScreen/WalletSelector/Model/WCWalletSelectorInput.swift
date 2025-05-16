//
//  WCWalletSelectorInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct WCWalletSelectorInput {
    let selectedWalletId: String
    let userWalletModels: [UserWalletModel]
    let selectWallet: (UserWalletModel) -> Void
    let backAction: () -> Void
}

extension WCWalletSelectorInput: Equatable {
    static func == (lhs: WCWalletSelectorInput, rhs: WCWalletSelectorInput) -> Bool {
        lhs.selectedWalletId == rhs.selectedWalletId
    }
}
