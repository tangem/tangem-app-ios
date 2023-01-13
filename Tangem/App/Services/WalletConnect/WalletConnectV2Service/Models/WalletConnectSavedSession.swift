//
//  WalletConnectSavedSession.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct WalletConnectSavedSession: Codable, Hashable, Identifiable {
    var id: Int { hashValue }
    let userWalletId: String
    let topic: String
    let sessionInfo: SessionInfo
}

extension WalletConnectSavedSession {
    struct SessionInfo: Codable, Hashable {
        let connectedBlockchains: [BlockchainNetwork]
        let dAppInfo: DAppInfo
    }

    struct DAppInfo: Codable, Hashable {
        let name: String
        let description: String
        let url: String
        let iconsLinks: [String]
        let supportedChains: [String]?
        var supportedMethods: [String]?
    }

}
