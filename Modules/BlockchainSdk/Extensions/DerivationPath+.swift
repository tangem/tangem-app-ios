//
//  DerivationPath+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public extension DerivationPath {
    func dropLastNode(count: Int) -> DerivationPath {
        return DerivationPath(nodes: nodes.dropLast(count))
    }

    /// `true` when every node's raw index fits the 31-bit BIP-32 child-index range.
    ///
    /// `DerivationPath(rawPath:)` accepts any `UInt32` literal, but BIP-32 reserves the top bit as the
    /// hardened flag: a non-hardened `2147483649` serializes to the same four bytes as `1'` (so two
    /// different-looking paths derive the same key), and a hardened index in that range overflows when
    /// the offset is added. Reject such paths before storing or deriving them.
    var hasValidNodeIndices: Bool {
        nodes.allSatisfy { $0.canonicalIndex != nil }
    }
}

public extension DerivationNode {
    /// The 32-bit BIP-32 child index as serialized on the wire (`rawIndex | hardened flag`),
    /// or `nil` when the raw index does not fit the 31-bit range and would overflow.
    ///
    /// Unlike `index`, this never traps on an out-of-range value.
    var canonicalIndex: UInt32? {
        switch self {
        case .hardened(let rawIndex):
            let (canonical, overflow) = rawIndex.addingReportingOverflow(Constants.hardenedOffset)
            return overflow ? nil : canonical
        case .nonHardened(let rawIndex):
            return rawIndex < Constants.hardenedOffset ? rawIndex : nil
        }
    }
}

private extension DerivationNode {
    enum Constants {
        /// BIP-32: indices `>= 2^31` are hardened; the raw (un-flagged) index must be `< 2^31`.
        static let hardenedOffset: UInt32 = 0x8000_0000
    }
}
