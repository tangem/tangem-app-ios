//
//  WalletConnectConnectedDApp.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import struct Foundation.Date

@available(iOS, deprecated: 100000.0, message: "Deprecated entry, isn't used in Accounts, will be removed in the future ([REDACTED_INFO])")
struct WalletConnectConnectedDAppV1: Hashable {
    let session: WalletConnectDAppSession
    let userWalletID: String
    let dAppData: WalletConnectDAppData
    let verificationStatus: WalletConnectDAppVerificationStatus
    let dAppBlockchains: [WalletConnectDAppBlockchain]
    let connectionDate: Date
}

// [REDACTED_TODO_COMMENT]
/// Wrapper over `WalletConnectConnectedDAppV1` to add `accountId` field for WalletConnect V2.
@dynamicMemberLookup
struct WalletConnectConnectedDAppV2: Hashable {
    subscript<T>(dynamicMember keyPath: KeyPath<WalletConnectConnectedDAppV1, T>) -> T {
        wrapped[keyPath: keyPath]
    }

    let accountId: String
    let wrapped: WalletConnectConnectedDAppV1
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
