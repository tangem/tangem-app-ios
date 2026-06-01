//
//  WalletConnectConnectedDApp.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.Date

struct WalletConnectConnectedDApp: Hashable {
    let accountId: String
    let session: WalletConnectDAppSession
    let userWalletID: String
    let dAppData: WalletConnectDAppData
    let verificationStatus: WalletConnectDAppVerificationStatus
    let dAppBlockchains: [WalletConnectDAppBlockchain]
    let connectionDate: Date

    func with(accountId: String) -> WalletConnectConnectedDApp {
        WalletConnectConnectedDApp(
            accountId: accountId,
            session: session,
            userWalletID: userWalletID,
            dAppData: dAppData,
            verificationStatus: verificationStatus,
            dAppBlockchains: dAppBlockchains,
            connectionDate: connectionDate
        )
    }
}

extension AccountModelPersistentIdentifierConvertible {
    var walletConnectIdentifierString: String {
        String(describing: toPersistentIdentifier())
    }
}
