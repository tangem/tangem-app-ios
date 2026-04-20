//
//  WalletUpdatingKeyType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum WalletUpdatingKeyType {
    case address(any Address)
    case addresses([any Address])
    case xpub(String)
}

// MARK: - Wallet + WalletUpdatingKeyType

extension Wallet {
    func updatingKeyType() throws -> WalletUpdatingKeyType {
        switch publicKey.derivationType {
        case .xpub(_, let xpub):
            let xpub = try XPUBUtils.generateXPUB(key: xpub, isTestnet: blockchain.isTestnet)
            let prefix = try XPUBUtils.prefix(blockchain: blockchain)
            return .xpub(prefix.wrap(xpub: xpub))
        case .none, .plain, .double:
            if addresses.count > 1 {
                return .addresses(addresses)
            }

            return .address(defaultAddress)
        }
    }
}
