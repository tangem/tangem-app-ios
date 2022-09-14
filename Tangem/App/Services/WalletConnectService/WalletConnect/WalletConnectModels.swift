//
//  WalletConnectModels.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import WalletConnectSwift
import TangemSdk

struct WalletInfo: Codable, Hashable {
    let walletPublicKey: Data
    let derivedPublicKey: Data?
    let derivationPath: DerivationPath?
    let blockchain: Blockchain

    var address: String {
        let blockchainKey = derivedPublicKey ?? walletPublicKey
        return try! blockchain.makeAddresses(from: blockchainKey, with: nil).first!.value
    }
}

struct WalletConnectSession: Codable, Hashable, Identifiable {
    var id: String { session.dAppInfo.peerId + "\(wallet.hashValue)" }

    func hash(into hasher: inout Hasher) {
        hasher.combine(wallet.hashValue)
        hasher.combine(session.dAppInfo.peerId)
    }

    var wallet: WalletInfo
    var session: Session
    var status: SessionStatus = .disconnected

    private enum CodingKeys: String, CodingKey {
        case wallet
        case session
    }
}

enum SessionStatus: Int, Codable {
    case disconnected
    case connecting
    case connected
}

extension Session: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.dAppInfo == rhs.dAppInfo && lhs.walletInfo == rhs.walletInfo
    }
}

extension Response {
    static func signature(_ signature: String, for request: Request) -> Response {
        return try! Response(url: request.url, value: signature, id: request.id!)
    }
}
