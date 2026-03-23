//
//  XPUBUtils.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

public struct XPUBUtils {
    public init() {}

    /// Returns additional derivation paths needed for XPUB generation.
    /// - **child** (account-level): leaf path with last 2 nodes dropped, e.g. `m/84'/0'/0'/0/0` → `m/84'/0'/0'`
    /// - **parent**: one level above child, e.g. `m/84'/0'/0'` → `m/84'/0'`
    public func xpubDerivationPaths(for derivationPath: DerivationPath) throws -> (child: DerivationPath, parent: DerivationPath) {
        guard derivationPath.nodes.count >= 4 else {
            throw Error.derivationPathTooShort
        }

        let childPath = derivationPath.dropLastNode(count: 2)
        let parentPath = derivationPath.dropLastNode(count: 3)

        return (child: childPath, parent: parentPath)
    }
}

// MARK: - Error

extension XPUBUtils {
    enum Error: String, LocalizedError {
        case derivationPathTooShort

        var errorDescription: String? {
            rawValue
        }
    }
}
