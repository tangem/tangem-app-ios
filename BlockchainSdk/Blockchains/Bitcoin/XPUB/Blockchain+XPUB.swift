//
//  Blockchain+XPUB.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

public extension Blockchain {
    var isXPUB: Bool {
        switch self {
        case .bitcoin(_, xpub: let xpub),
             .litecoin(xpub: let xpub),
             .bitcoinCash(xpub: let xpub),
             .dogecoin(xpub: let xpub),
             .dash(_, xpub: let xpub),
             .ravencoin(_, xpub: let xpub):
            return xpub
        default:
            return false
        }
    }

    func updatedIfSupported(xpub enabled: Bool) -> Self {
        do {
            let blockchain = try updated(xpub: enabled)
            return blockchain
        } catch {
            return self
        }
    }

    func updated(xpub enabled: Bool) throws -> Self {
        switch self {
        case .bitcoin(let testnet, _):
            return .bitcoin(testnet: testnet, xpub: enabled)
        case .litecoin:
            return .litecoin(xpub: enabled)
        case .bitcoinCash:
            return .bitcoinCash(xpub: enabled)
        case .dogecoin:
            return .dogecoin(xpub: enabled)
        case .dash(let testnet, _):
            return .dash(testnet: testnet, xpub: enabled)
        case .ravencoin(let testnet, _):
            return .ravencoin(testnet: testnet, xpub: enabled)
        default:
            throw XPUBError.blockchainNotSupportXPUB(displayName)
        }
    }
}

enum XPUBError: LocalizedError {
    case blockchainNotSupportXPUB(String)
}
