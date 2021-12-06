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
    let cid: String
    let walletPublicKey: Data
    let derivedPublicKey: Data?
    let derivationPath: DerivationPath?
    let blockchain: Blockchain
    let chainId: Int?
    
    var address: String {
        let blockchainKey = derivedPublicKey ?? walletPublicKey
        return blockchain.makeAddresses(from: blockchainKey, with: nil).first!.value
    }
    
    internal init(cid: String, walletPublicKey: Data, derivedPublicKey: Data?, derivationPath: DerivationPath?, blockchain: Blockchain, chainId: Int?) {
        self.cid = cid
        self.walletPublicKey = walletPublicKey
        self.derivedPublicKey = derivedPublicKey
        self.derivationPath = derivationPath
        self.blockchain = blockchain
        self.chainId = chainId
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

extension Response {
    static func signature(_ signature: String, for request: Request) -> Response {
        return try! Response(url: request.url, value: signature, id: request.id!)
    }
}
