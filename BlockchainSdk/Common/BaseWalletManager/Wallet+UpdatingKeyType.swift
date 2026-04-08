//
//  WalletUpdatingKeyType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum WalletUpdatingKeyType {
    case address(any Address)
    case addresses(default: any Address, legacy: any Address)
    case xpub(String)
}

// MARK: - Wallet + WalletUpdatingKeyType

extension Wallet {
    func updatingKeyType() throws -> WalletUpdatingKeyType {
        switch publicKey.derivationType {
        case .xpub(_, let xpub):
            let xpub = try XPUBUtils().generateXPUB(key: xpub, isTestnet: blockchain.isTestnet)
            return .xpub(xpub)
        case _ where legacyAddress != nil:
            return .addresses(default: defaultAddress, legacy: legacyAddress!)
        case _:
            return .address(defaultAddress)
        }
    }
}
