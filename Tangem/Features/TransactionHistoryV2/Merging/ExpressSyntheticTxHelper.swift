//
//  ExpressSyntheticTxHelper.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// Single source of truth for the identifier of a synthetic Express (swap/onramp) history record — one that has
/// no matching on-chain transaction yet. The identifier is derived from the Express `txId` with a prefix, so it
/// can't collide with a real on-chain hash and is recognizable as non-on-chain (the details sheet uses that to
/// avoid offering explore / hash-copy for such records).
struct ExpressSyntheticTxHelper {
    private static let prefix = "ExpressSyntheticTx_"

    private let txId: String

    init(txId: String) {
        self.txId = txId
    }

    func makeSyntheticTxIdentifier() -> String {
        Self.prefix + txId
    }

    func isMatchingTxIdentifier(_ identifier: String) -> Bool {
        identifier == makeSyntheticTxIdentifier()
    }

    /// Whether `identifier` is a synthetic Express identifier rather than a real on-chain hash.
    static func isSyntheticIdentifier(_ identifier: String) -> Bool {
        identifier.hasPrefix(prefix)
    }
}
