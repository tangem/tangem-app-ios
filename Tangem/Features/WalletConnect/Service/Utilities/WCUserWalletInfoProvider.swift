//
//  WCUserWalletInfoProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

protocol WCUserWalletInfoProvider: AnyObject {
    var userWalletId: UserWalletId { get }
    var signer: TangemSigner { get }
    var wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider { get }
}
