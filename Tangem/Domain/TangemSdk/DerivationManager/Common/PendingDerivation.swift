//
//  PendingDerivation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct TangemSdk.DerivationPath

struct PendingDerivation {
    let network: BlockchainNetwork
    let masterKey: KeyInfo
    let paths: [DerivationPath]
}

// MARK: - Equatable

extension PendingDerivation: Equatable {
    static func == (lhs: PendingDerivation, rhs: PendingDerivation) -> Bool {
        lhs.network == rhs.network && lhs.masterKey.publicKey == rhs.masterKey.publicKey && lhs.paths == rhs.paths
    }
}

// MARK: - Hashable

extension PendingDerivation: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(network)
        hasher.combine(masterKey.publicKey)
        hasher.combine(paths)
    }
}
