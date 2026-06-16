//
//  WalletUpdatingKeyType.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

public enum WalletUpdatingKeyType {
    case address(any Address)
    case addresses([any Address])
    case xpub(UTXOXpubScriptType)
    case xpubs([UTXOXpubScriptType])
}

// MARK: - Wallet + WalletUpdatingKeyType

public extension Wallet {
    func updatingKeyType() throws -> WalletUpdatingKeyType {
        switch publicKey.derivationType {
        case .xpub(_, let xpub):
            let xpub = try XPUBUtils.generateXPUB(key: xpub, isTestnet: blockchain.isTestnet)
            let scriptTypes = try XPUBUtils.scriptTypes(blockchain: blockchain, xpub: xpub)

            if let single = scriptTypes.singleElement {
                return .xpub(single)
            }

            return .xpubs(scriptTypes)
        case .none, .plain, .double:
            if let single = addresses.singleElement {
                return .address(single)
            }

            return .addresses(addresses)
        }
    }
}
