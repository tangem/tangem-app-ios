//
//  TokenSelectorExpandedStateStorage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation

protocol TokenSelectorExpandedStateStorage: AnyObject {
    func isWalletOpen(_ walletId: UserWalletId) -> Bool
    func setWalletOpen(_ open: Bool, for walletId: UserWalletId)
    func makeAccountStateStorage(for userWalletId: UserWalletId) -> ExpandableAccountItemStateStorage
}
