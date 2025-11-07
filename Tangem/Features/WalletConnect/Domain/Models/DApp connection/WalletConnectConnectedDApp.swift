//
//  WalletConnectConnectedDApp.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.Date

struct WalletConnectConnectedDAppV1: Hashable {
    let session: WalletConnectDAppSession
    let userWalletID: String
    let dAppData: WalletConnectDAppData
    let verificationStatus: WalletConnectDAppVerificationStatus
    let dAppBlockchains: [WalletConnectDAppBlockchain]
    let connectionDate: Date
}

struct WalletConnectConnectedDAppV2: Hashable {
    let session: WalletConnectDAppSession
    let accountId: String
    let dAppData: WalletConnectDAppData
    let verificationStatus: WalletConnectDAppVerificationStatus
    let dAppBlockchains: [WalletConnectDAppBlockchain]
    let connectionDate: Date
}

enum WalletConnectConnectedDApp: Hashable {
    case v1(WalletConnectConnectedDAppV1)
    case v2(WalletConnectConnectedDAppV2)

    var session: WalletConnectDAppSession {
        switch self {
        case .v1(let dApp): return dApp.session
        case .v2(let dApp): return dApp.session
        }
    }

    var dAppData: WalletConnectDAppData {
        switch self {
        case .v1(let dApp): return dApp.dAppData
        case .v2(let dApp): return dApp.dAppData
        }
    }

    var verificationStatus: WalletConnectDAppVerificationStatus {
        switch self {
        case .v1(let dApp): return dApp.verificationStatus
        case .v2(let dApp): return dApp.verificationStatus
        }
    }

    var dAppBlockchains: [WalletConnectDAppBlockchain] {
        switch self {
        case .v1(let dApp): return dApp.dAppBlockchains
        case .v2(let dApp): return dApp.dAppBlockchains
        }
    }

    var connectionDate: Date {
        switch self {
        case .v1(let dApp): return dApp.connectionDate
        case .v2(let dApp): return dApp.connectionDate
        }
    }

    var userWalletID: String? {
        switch self {
        case .v1(let dApp): return dApp.userWalletID
        case .v2: return nil
        }
    }

    var accountId: String? {
        switch self {
        case .v1: return nil
        case .v2(let dApp): return dApp.accountId
        }
    }
}

extension AccountModelPersistentIdentifierConvertible {
    var walletConnectIdentifierString: String {
        String(describing: toPersistentIdentifier())
    }
}
