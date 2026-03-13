//
//  WalletConnectConnectedDApp.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.Date

// [REDACTED_TODO_COMMENT]
struct WalletConnectConnectedDAppV2: Hashable {
    let session: WalletConnectDAppSession
    let userWalletID: String
    let accountId: String
    let dAppData: WalletConnectDAppData
    let verificationStatus: WalletConnectDAppVerificationStatus
    let dAppBlockchains: [WalletConnectDAppBlockchain]
    let connectionDate: Date
}

enum WalletConnectConnectedDApp: Hashable {
    case v2(WalletConnectConnectedDAppV2)

    var session: WalletConnectDAppSession {
        switch self {
        case .v2(let dApp): return dApp.session
        }
    }

    var dAppData: WalletConnectDAppData {
        switch self {
        case .v2(let dApp): return dApp.dAppData
        }
    }

    var verificationStatus: WalletConnectDAppVerificationStatus {
        switch self {
        case .v2(let dApp): return dApp.verificationStatus
        }
    }

    var dAppBlockchains: [WalletConnectDAppBlockchain] {
        switch self {
        case .v2(let dApp): return dApp.dAppBlockchains
        }
    }

    var connectionDate: Date {
        switch self {
        case .v2(let dApp): return dApp.connectionDate
        }
    }

    var accountId: String? {
        switch self {
        case .v2(let dApp): return dApp.accountId
        }
    }
}

extension AccountModelPersistentIdentifierConvertible {
    var walletConnectIdentifierString: String {
        String(describing: toPersistentIdentifier())
    }
}
