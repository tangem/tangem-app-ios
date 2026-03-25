//
//  WalletModelSendingRestrictionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct WalletModelSendingRestrictionsProvider: SendingRestrictionsProvider {
    let walletModel: any WalletModel

    var sendingRestrictions: SendingRestrictions? { walletModel.sendingRestrictions }
}
