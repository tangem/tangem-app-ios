//
//  StakingWallet.swift
//  TangemStaking
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import CryptoKit

public struct StakingWallet: Hashable {
    public let item: StakingTokenItem
    public let address: String
    public let publicKey: Data

    public init(item: StakingTokenItem, address: String, publicKey: Data) {
        self.item = item
        self.address = address
        self.publicKey = publicKey
    }

    public var cacheId: String {
        let digest = SHA256.hash(data: publicKey)
        let hash = Data(digest).hexString
        return "\(item.network)_\(item.contractAddress ?? "coin")_\(hash)"
    }
}
