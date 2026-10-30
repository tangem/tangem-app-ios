//
//  WCUserWalletInfoProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

protocol WCUserWalletInfoProvider: AnyObject {
    var wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider { get }
}
