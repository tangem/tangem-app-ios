//
//  SendingRestrictionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

protocol SendingRestrictionsProvider {
    var sendingRestrictions: SendingRestrictions? { get }
}

struct CommonSendingRestrictionsProvider: SendingRestrictionsProvider {
    let walletModel: any WalletModel

    var sendingRestrictions: SendingRestrictions? { walletModel.sendingRestrictions }
}
