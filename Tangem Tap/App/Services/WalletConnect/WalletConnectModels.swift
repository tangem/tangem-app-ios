//
//  WalletConnectModels.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import WalletConnectSwift

struct WalletInfo: Codable, Hashable {
    let cid: String
    let walletPublicKey: Data
    let isTestnet: Bool
    
    var address: String {
        Blockchain.ethereum(testnet: isTestnet).makeAddresses(from: walletPublicKey, with: nil).first!.value
    }
    
    var chainId: Int { isTestnet ? 4 : 1 }
    
    internal init(cid: String, walletPublicKey: Data, isTestnet: Bool) {
        self.cid = cid
        self.walletPublicKey = walletPublicKey
        self.isTestnet = isTestnet
    }
}

struct WalletConnectSession: Codable, Hashable, Identifiable {
    var id: String { session.dAppInfo.peerId + "\(wallet.hashValue)" }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(wallet.hashValue)
        hasher.combine(session.dAppInfo.peerId)
    }
    
    let wallet: WalletInfo
    var session: Session
    var status: SessionStatus = .disconnected
    
    private enum CodingKeys: String, CodingKey {
        case wallet, session
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
